defmodule TalkWeb.Plug.CurrentUser do
  @moduledoc "Plug to insert current user to Plug.Conn struct for graphql endpoint"

  import Plug.Conn, only: [assign: 3]
  require Logger
  def init(default), do: default

  def call(conn, _default) do
    with {:ok, user} <- TalkWeb.Auth.current_user(conn) do
      assign(conn, :user, user)
    else
      {:error, :not_found} ->
        conn

      err -> err
    end
  end
end
