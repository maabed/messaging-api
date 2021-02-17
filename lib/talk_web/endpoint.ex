defmodule TalkWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :talk
  use Absinthe.Phoenix.Endpoint

  @origins Application.get_env(:talk, :allowed_origins)

  socket "/socket", TalkWeb.UserSocket,
    websocket: [
      timeout: 100_000,
      check_origin: @origins,
      transport_log: :error,
      compress: true
    ]

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  # plug Logster.Plugs.Logger
  # Add Timber plugs for capturing HTTP context and events
  # plug(Timber.Plug.HTTPContext)
  # plug(Timber.Plug.Event)

  plug Plug.Logger
  plug Plug.RequestId
  # new logs using luki and LoggerJSON
  # plug LoggerJSON.Plug
  # plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]
  # plug TalkWeb.PlugPipelineInstrumenter
  # plug TalkWeb.PlugExporter

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Static,
    at: "/",
    from: :talk,
    gzip: true,
    only: ~w(css images js),
    only_matching: ~w(favicon robots)

  # plug Corsica,
  #   origins: ["http://localhost:3000", "http://localhost:7000", ~r{^https?://(.*\.?)sapien\.network$}, ~r{^https?://(.*\.?)ngrok\.io$}, "http://sapien-front.ngrok.io", "https://sapien-front.eu.ngrok.io"],
  #   allow_headers: :all,
  #   allow_methods: ["HEAD", "GET"],
  #   allow_credentials: true,
  #   log: [rejected: :error, invalid: :warn],
  #   max_age: 3600

  plug TalkWeb.Router

  def init(_key, config) do
    if config[:load_from_system_env] do
      port = System.fetch_env!("PORT")

      case Integer.parse(port) do
        {_int, ""} ->
          host = System.fetch_env!("HOST")
          secret_key_base = System.fetch_env!("SECRET_KEY_BASE")

          config = put_in(config[:http][:port], port)
          config = put_in(config[:url][:host], host)
          config = put_in(config[:secret_key_base], secret_key_base)
          config = put_in(config[:check_origin], ["//#{host}"])

          {:ok, config}

        :error ->
          {:ok, config}
      end
    else
      {:ok, config}
    end
  end
end
