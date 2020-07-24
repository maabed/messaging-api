defmodule TalkWeb.Plug.ConnInterceptor do
  require Logger

  def init(default), do: default

  def call(conn, _default) do
    Logger.warn("Interceptor [Headers]: #{inspect conn.req_headers, pretty: true}")
    conn
  end
end
