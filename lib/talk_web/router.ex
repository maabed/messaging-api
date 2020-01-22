defmodule TalkWeb.Router do
  use TalkWeb, :router
  use Plug.ErrorHandler
  require Logger
  @env Mix.env()

  pipeline :graphiql do
    plug :accepts, ["json"]
  end

  pipeline :graphql do
    plug :accepts, ["json"]
    plug :user_agent
    plug :validate_url
    # plug :secure_headers
    plug TalkWeb.Plug.AuthPipeline
  end

  scope "/" do
    forward "/health-check", TalkWeb.HealthChecks
  end

  scope "/" do
    if @env == :dev do
      forward "/graphiql", Absinthe.Plug.GraphiQL,
        schema: TalkWeb.Schema,
        socket: TalkWeb.UserSocket,
        interface: :playground,
        default_url: "/chat-graphql"
    end
  end

  scope "/" do
    pipe_through :graphql
    forward "/chat-graphql", Absinthe.Plug, schema: TalkWeb.Schema
    match(:*, "/*path", TalkWeb.Fallback, :not_found)
  end

  defp handle_errors(conn, %{kind: kind, reason: reason, stack: _stacktrace}) do
    if report?(kind, reason) do
      conn = maybe_fetch_params(conn)
      url = "#{conn.scheme}://#{conn.host}:#{conn.port}#{conn.request_path}"
      user_ip = conn.remote_ip |> :inet.ntoa() |> List.to_string()
      headers = conn.req_headers |> Map.new() |> filter_headers()
      endpoint_url = TalkWeb.Endpoint.config(:url)

      data = %{
        "request" => %{
          "url" => url,
          "user_ip" => user_ip,
          "headers" => headers,
          "params" => conn.params,
          "method" => conn.method
        },
        "server" => %{
          "host" => endpoint_url[:host],
          "root" => endpoint_url[:path]
        }
      }

      Logger.warn("error kind ==> #{inspect kind}")
      Logger.warn("error reason ==> #{inspect reason}")
      Logger.warn("error report data ==> #{inspect data}")
      data
    end
  end

  defp report?(:error, exception), do: Plug.Exception.status(exception) == 500
  defp report?(_kind, _reason), do: true

  defp maybe_fetch_params(conn) do
    try do
      Plug.Conn.fetch_query_params(conn)
    rescue
      _ ->
        %{conn | params: "[UNFETCHED]"}
    end
  end

  @filter_headers ~w(authorization)

  defp filter_headers(headers) do
    Map.drop(headers, @filter_headers)
  end
end
