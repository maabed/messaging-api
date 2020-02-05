defmodule TalkWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :talk
  use Absinthe.Phoenix.Endpoint

  @origins Application.get_env(:talk, :allowed_origins)

  socket "/socket", TalkWeb.UserSocket,
    websocket: [
      timeout: 45_000,
      check_origin: @origins
    ]

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  # plug Logster.Plugs.Logger
  # plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
  # Add Timber plugs for capturing HTTP context and events
  # plug(Timber.Plug.HTTPContext)
  # plug(Timber.Plug.Event)

  plug Plug.Logger
  plug Plug.RequestId

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug Plug.MethodOverride
  plug Plug.Head

  plug Corsica,
    origins: ["http://localhost:3000", "http://localhost:7000", ~r{^https?://(.*\.?)sapien\.network$}],
    allow_headers: ~w(Accept Content-Type Authorization Origin user-agent),
    allow_methods: ["HEAD", "GET"],
    log: [rejected: :error, invalid: :warn],
    max_age: 3600

  plug TalkWeb.Router
end
