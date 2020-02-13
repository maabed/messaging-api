import Config

origins = ["//localhost:3000", "//localhost:7000", "//*.sapien.network", "https://*.sapien.network"]
audience = ["sapien.network", "beta.sapien.network", "talk.sapien.network", "notifier.sapien.network"]

config :talk,
  ecto_repos: [Talk.Repo],
  env: Mix.env(),
  jwt_aud: audience,
  user_agent_req: false,
  allowed_origins: origins,
  giphy_url: "https://media.giphy.com/media"

config :talk, Talk.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  migration_source: "chat_migrations",
  migration_timestamps: [type: :utc_datetime_usec],
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "20")

config :talk, TalkWeb.Endpoint,
  url: [host: System.get_env("HOST")],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: TalkWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Talk.PubSub, adapter: Phoenix.PubSub.PG2],
  check_origin: origins

config :talk, TalkWeb.Auth,
  issuer: "sapien",
  ttl: {120, :days},
  allowed_algos: ["RS256"],
  allowed_drift: 2000,
  verify_issuer: true,
  secret_fetcher: TalkWeb.Auth.SecretFetcher

config :talk, :asset_store,
  bucket: System.get_env("ASSET_STORE_BUCKET"),
  avatar_bucket: System.get_env("ASSET_AVATAR_DIR"),
  adapter: Talk.AssetStore.S3Adapter

config :ex_aws,
  debug_requests: true,
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
  region: "us-east-1"

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :absinthe, log: false

config :phoenix, :generators,
  migration: true,
  binary_id: false

config :phoenix, :json_library, Jason

config :tzdata, :autoupdate, :disabled

import_config "#{Mix.env()}.exs"

# import_config "timber.exs"
