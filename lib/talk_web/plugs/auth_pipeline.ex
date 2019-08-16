defmodule TalkWeb.Plug.AuthPipeline do
  @moduledoc "Module to define guardian related plugs into a pipeline"

  import Plug.Conn, only: [send_resp: 3]

  @claims %{typ: "access"}

  use Guardian.Plug.Pipeline,
    otp_app: :talk,
    module: TalkWeb.Auth,
    error_handler: __MODULE__

  plug Guardian.Plug.VerifyHeader, claims: @claims
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, allow_blank: true
  plug TalkWeb.Plug.CurrentUser
  plug TalkWeb.Plug.Graphql

  def auth_error(conn, {type, _reason}, _opts) do
    body = Jason.encode!(%{message: to_string(type)})
    send_resp(conn, 401, body)
  end
end
