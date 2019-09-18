defmodule TalkWeb.Plug.CurrentUser do
  @moduledoc "Plug to insert current user to Plug.Conn struct for graphql endpoint"

  import Plug.Conn, only: [assign: 3]

  def init(default), do: default

  def call(conn, _default) do
    user = TalkWeb.Auth.current_user(conn)
    assign(conn, :user, user)
  end
end