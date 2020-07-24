defmodule TalkWeb.Fallback do
  import Plug.Conn, only: [resp: 3, halt: 1]
  require Logger

  def init(opts), do: opts

  def call(conn, :bad_request) do
    conn
    |> resp(400, "Bad request")
    |> halt()
  end

  def call(conn, :unauthorized) do
    conn
    |> resp(401, "Unauthorized")
    |> halt()
  end

  def call(conn, :forbidden) do
    conn
    |> resp(403, "Forbidden")
    |> halt()
  end

  def call(conn, :not_found) do
    conn
    |> resp(404, "Not found")
    |> halt()
  end

  def call(conn, _) do
    conn
    |> resp(500, "Internal server error")
    |> halt()
  end
end
