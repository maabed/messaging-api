defmodule Mix.Tasks.Talk.GenAuthToken do
  @moduledoc """
  Gets the authentication token of a user.
  """

  @shortdoc "Gets the authentication token of a user."

  use Mix.Task
  import Mix, only: [shell: 0]

  alias Talk.Users
  alias TalkWeb.Auth

  @switches [
    id: :string,
    email: :string,
    username: :string
  ]

  @doc false
  def run(args) do
    Mix.Task.run("app.start")

    args
    |> parse_opts()
    |> do_run()
  end

  defp do_run(opts) do
    user =
      cond do
        Keyword.has_key?(opts, :id) -> %{id: Keyword.get(opts, :id)}
        Keyword.has_key?(opts, :email) -> %{email: Keyword.get(opts, :email)}
        Keyword.has_key?(opts, :username) -> %{username: Keyword.get(opts, :username)}
      end

    user
    |> get_user()
    |> get_token()
    |> print_token()
  end

  defp get_user(%{id: id}), do: Users.get_user_by_id(id)
  defp get_user(%{email: email}), do: Users.get_user_by_email(email)
  defp get_user(%{username: username}), do: Users.get_user_by_username(username)

  defp get_token({:ok, user}) do
    {:ok, token} = Auth.generate_token(user)

    token
  end

  defp print_token(token), do: shell().info("Success!\nToken: #{token}")

  defp parse_opts(args) do
    {opts, _, _} = OptionParser.parse(args, switches: @switches)

    opts
  end
end
