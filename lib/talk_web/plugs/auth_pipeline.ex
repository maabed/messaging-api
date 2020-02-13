defmodule TalkWeb.Plug.AuthPipeline do
  @moduledoc "Module to define guardian related plugs into a pipeline"

  import Plug.Conn, only: [send_resp: 3]
  require Logger
  use Guardian.Plug.Pipeline,
    otp_app: :talk,
    module: TalkWeb.Auth,
    error_handler: __MODULE__

  plug Guardian.Plug.VerifyHeader, realm: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, allow_blank: true
  plug TalkWeb.Plug.CurrentUser
  plug TalkWeb.Plug.Graphql
  plug TalkWeb.Plug.ConnInterceptor # good for debugging

  def auth_error(conn, {type, reason}, opts) do
    Logger.warn("Auth Error [type] #{inspect type}")
    Logger.warn("Auth Error [reason] #{inspect reason}")
    Logger.warn("Auth Error [opts] #{inspect opts}")
    Logger.warn("Interceptor [Headers]: #{inspect conn.req_headers}")
    body = Jason.encode!(%{message: to_string(type)})
    send_resp(conn, 401, body)
  end
end
