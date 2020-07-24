defmodule Talk.MixProject do
  @moduledoc "Mix file"

  use Mix.Project

  @elixir_version "~> 1.10.0"
  @version "0.1.0"

  def project do
    [
      app: :talk,
      version: @version,
      elixir: @elixir_version,
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      releases: releases(),
      deps: deps(),
      name: "Talk",
      source_url: "https://github.com/SapienNetwork/sapien-chat"
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Talk, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:absinthe, "~> 1.4"},
      {:absinthe_plug, "~> 1.4"},
      {:absinthe_phoenix, "~> 1.4"},
      {:dataloader, "~> 1.0"},
      {:phoenix, "~> 1.4.11"},
      {:phoenix_pubsub, "~> 1.1.2"},
      {:phoenix_ecto, "~> 4.1.0"},
      {:guardian, "~> 2.0"},
      {:ecto_sql, "~> 3.3.3"},
      {:postgrex, "~> 0.15.0"},
      {:gettext, "~> 0.11"},
      {:corsica, "~> 1.0"},
      {:jason, "~> 1.0"},
      {:timex, "~> 3.6"},
      {:csv, "~> 2.3"},
      {:credo, "~>  1.1", only: [:dev, :test], runtime: false},
      # {:logster, "~> 1.0"},
      {:plug_cowboy, "~> 2.1.1"},
      # AWS S3 deps
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:hackney, github: "benoitc/hackney", override: true},
      {:sweet_xml, "~> 0.6.6"}
      # timber logger
      # {:timber, "~> 3.1"},
      # {:timber_ecto, "~> 2.0"},
      # {:timber_phoenix, "~> 1.0"},
      # {:timber_plug, "~> 1.0"}

    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.migrate": ["ecto.migrate"],
      "ecto.reset": ["ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  defp releases() do
    [
      talk: [
        include_executables_for: [:unix]
      ]
    ]
  end
end
