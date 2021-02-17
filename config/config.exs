import Config

origins = ["//localhost:3000", "//localhost:7000", "//*.sapien.network", "https://*.sapien.network"]
audience = ["sapien.network", "beta.sapien.network", "talk.sapien.network", "notifier.sapien.network"]

config :talk,
  ecto_repos: [Talk.Repo],
  env: Mix.env(),
  jwt_aud: audience,
  user_agent_req: false,
  allowed_origins: origins,
  priv_key: System.get_env("JWT_PRIVATE_KEY"),
  giphy_url: "https://media.giphy.com/media",
  bucket: System.get_env("ASSET_STORE_BUCKET"),
  avatar_dir: System.get_env("ASSET_AVATAR_DIR"),
  cdn_prefix: System.get_env("CDN_PREFIX"),
  redis_url: URI.parse(System.get_env("REDIS_URL") || "redis://127.0.0.1:6379"),
  onesignal_app_id: System.get_env("ONESIGNAL_APP_ID"),
  onesignal_app_key: System.get_env("ONESIGNAL_APP_KEY")

config :talk, Talk.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  migration_source: "chat_migrations",
  migration_timestamps: [type: :utc_datetime_usec],
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "60")
  # loggers: [{LoggerJSON.Ecto, :log, [:info]}]

config :talk, TalkWeb.Endpoint,
  url: [host: System.get_env("HOST")],
  root: Path.dirname(__DIR__),
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: TalkWeb.ErrorView, accepts: ~w(json)],
  pubsub_server: Talk.PubSub,
  check_origin: origins


config :talk, TalkWeb.Auth,
  issuer: "sapien",
  ttl: {120, :days},
  allowed_algos: ["RS256"],
  allowed_drift: 2000,
  verify_issuer: true,
  secret_fetcher: TalkWeb.Auth.SecretFetcher

config :ex_aws,
  debug_requests: true,
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
  region: "us-east-1"

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :absinthe, log: false

# new logs using luki and LoggerJSON
# config :logger, backends: [LoggerJSON]
# config :logger_json, :backend,
#   metadata: [:file, :line, :function, :module, :application, :httpRequest, :query, :request_id],
#   formatter: Talk.LoggerFormatter,
#   level: :info

# config :prometheus, TalkWeb.PlugExporter,
#   path: "/metrics",
#   format: :auto,
#   registry: :default
# config :phoenix, :logger, false

config :phoenix, :generators,
  migration: true,
  binary_id: false

config :phoenix, :json_library, Jason

config :tzdata, :autoupdate, :disabled

import_config "#{Mix.env()}.exs"
