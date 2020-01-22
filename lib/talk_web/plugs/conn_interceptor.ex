defmodule TalkWeb.Plug.ConnInterceptor do
  require Logger

  def init(default), do: default

  def call(conn, _default) do
    Logger.warn("headers: #{inspect conn.req_headers}")
    conn
  end
end
