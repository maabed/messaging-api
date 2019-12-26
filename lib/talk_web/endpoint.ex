defmodule TalkWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :talk
  use Absinthe.Phoenix.Endpoint

  @origins Application.get_env(:talk, :origins)

  socket "/socket", TalkWeb.UserSocket,
    websocket: [
      timeout: 45_000,
      check_origin: @origins
    ]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :talk,
    gzip: true,
    only: ~w(robots.txt),
    headers: [{"access-control-allow-origin", "*"}]

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  # plug Plug.Logger
  plug Logster.Plugs.Logger
  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session,
    store: :cookie,
    key: "_talk_key",
    signing_salt: "HnGlMbxh"

  plug TalkWeb.Router
end
