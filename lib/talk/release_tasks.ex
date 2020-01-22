defmodule Talk.ReleaseTasks do
  require Logger
  import Ecto.Query, warn: false
  alias Talk.Repo
  use Ecto.Migration

  @repo_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto_sql
  ]

  @repos Application.get_env(:talk, :ecto_repos, [])

  def migrate(args \\ []) do
    {:ok, _} = Application.ensure_all_started(:logger)
    Logger.info("[task] running migrate")
    start_repos()

    run_migrations(args)

    Logger.info("[task] finished migrate")
    stop()
  end

  def rollback(args \\ []) do
    {:ok, _} = Application.ensure_all_started(:logger)
    Logger.info("[task] running rollback")
    start_repos()

    run_rollback(args)

    Logger.info("[task] finished rollback")
    stop()
  end

  def seed(args \\ []) do
    {:ok, _} = Application.ensure_all_started(:logger)
    Logger.info("[task] running seed")
    start_repos()

    run_migrations(args)
    run_seeds()

    Logger.info("[task] finished seed")
    stop()
  end

  def restart() do
    Logger.info("[task] Stopping Talk...")
    :ok = Application.stop(:talk)
    Logger.info("[task] Talk stopped. Restarting...")
    {:ok, _}  =  Application.ensure_all_started(:talk)
    Logger.info("[task] Talk restarted.")
  end

  def start_app() do
    IO.puts("Starting app...")
    {:ok, _} = Application.ensure_all_started(:talk)
  end

  defp start_repos() do
    IO.puts("Starting dependencies...")
    Enum.each(@repo_apps, fn app ->
      {:ok, _} = Application.ensure_all_started(app)
    end)

    IO.puts("Starting repos...")
    :ok = Application.load(:talk)

    Enum.each(@repos, fn repo ->
      {:ok, _} = repo.start_link(pool_size: 2)
    end)
  end

  defp stop() do
    IO.puts("Stopping...")
    :init.stop()
  end

  defp run_migrations(args) do
    Enum.each(@repos, fn repo ->
      app = Keyword.get(repo.config(), :otp_app)
      IO.puts("Running migrations for #{app}")

      case args do
        ["--step", n] -> migrate(repo, :up, step: String.to_integer(n))
        ["-n", n] -> migrate(repo, :up, step: String.to_integer(n))
        ["--to", to] -> migrate(repo, :up, to: to)
        ["--all"] -> migrate(repo, :up, all: true)
        [] -> migrate(repo, :up, all: true)
      end
    end)
  end

  defp run_rollback(args) do
    Enum.each(@repos, fn repo ->
      app = Keyword.get(repo.config(), :otp_app)
      IO.puts("Running rollback for #{app}")

      case args do
        ["--step", n] -> migrate(repo, :down, step: String.to_integer(n))
        ["-n", n] -> migrate(repo, :down, step: String.to_integer(n))
        ["--to", to] -> migrate(repo, :down, to: to)
        ["--all"] -> migrate(repo, :down, all: true)
        [] -> migrate(repo, :down, step: 1)
      end
    end)
  end

  defp migrate(repo, direction, opts) do
    migrations_path = priv_path_for(repo, "migrations")
    Ecto.Migrator.run(repo, migrations_path, direction, opts)
  end

  def run_seeds() do
    Enum.each(@repos, &run_seeds_for/1)
  end

  defp run_seeds_for(repo) do
    # Run the seed script if it exists
    seed_script = priv_path_for(repo, "seeds.exs")

    if File.exists?(seed_script) do
      IO.puts("Running seed script...")
      Code.eval_file(seed_script)
    end
  end

  defp priv_path_for(repo, filename) do
    app = Keyword.get(repo.config(), :otp_app)
    priv_dir = Application.app_dir(app, "priv")

    Path.join([priv_dir, "repo", filename])
  end

  def migration_status() do
    latest_migration = Application.app_dir(:talk, "priv/repo/migrations")
    |> File.ls!
    |> Enum.max
    |> String.split("_", parts: 2)
    |> List.first
    |> String.to_integer

    Logger.info("latest_migration #{inspect latest_migration}")

    # Perform similar logic to see what's latest in the database
    latest_applied_migration = Enum.max(Ecto.Migrator.migrated_versions(Repo), fn -> :not_found end)
    Logger.info("latest_applied_migration #{inspect latest_applied_migration}")


    if latest_applied_migration == latest_migration do
      :ok
    else
      {:error, latest_applied_migration, latest_migration}
    end
  end
end
