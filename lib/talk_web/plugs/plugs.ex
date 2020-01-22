defmodule TalkWeb.Plugs do
  import Plug.Conn

  def validate_url(conn, _opts) do
    if String.contains?(conn.request_path <> conn.query_string, "%00") do
      conn
      |> resp(400, "could not be resolved.")
      |> halt()
    else
      conn
    end
  end

  def secure_headers(conn, _params) do
    conn
    |> merge_resp_headers([
      {"x-frame-options", "DENY"},
      {"x-xss-protection", "1; mode=block"},
      {"x-content-type-options", "nosniff"},
      {"strict-transport-security", "max-age=31536000; includeSubDomains"}
    ])
  end

  def user_agent(conn, _opts) do
    case get_req_header(conn, "user-agent") do
      [value | _] ->
        assign(conn, :user_agent, value)

      [] ->
        if Application.get_env(:talk, :user_agent_req) do
          conn
          |> resp(400, "User-Agent header is required.")
          |> halt()
        else
          assign(conn, :user_agent, "missing")
        end
    end
  end

  def web_user_agent(conn, _opts) do
    assign(conn, :user_agent, "WEB")
  end
end
