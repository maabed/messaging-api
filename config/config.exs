use Mix.Config

config :talk,
  ecto_repos: [Talk.Repo],
  env: Mix.env()

config :talk, Talk.Repo, migration_timestamps: [type: :utc_datetime_usec]

config :talk, TalkWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "IXE7RLjiC2vuP8lx8AxxWJr3xulxnEqCCH/s80Y7p1fL7zW8lA/WOOx2qigjw5eX",
  render_errors: [view: TalkWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Talk.PubSub, adapter: Phoenix.PubSub.PG2],
  watchers: []

config :talk, TalkWeb.Auth,
  issuer: "sapien",
  ttl: {120, :days},
  secret_key: "0B1xZiXa9OqHSSR7KhAwTRD3GSDoXB3N8S1VOHyr4pL5Bi0YdMqX9/FWDxHWXRwL"
  # allowed_algos: ["ES256"],
  # secret_fetcher: TalkWeb.Auth.SecretFetcher

config :talk,
  basic_auth: [
    username: System.get_env("BASIC_AUTH_USERNAME"),
    password: System.get_env("BASIC_AUTH_PASSWORD"),
    realm: "GraphiQL Endpoint"
  ]

config :talk, :asset_store,
  bucket: System.get_env("ASSET_STORE_BUCKET"),
  adapter: Talk.AssetStore.S3Adapter

config :ex_aws,
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY")

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :absinthe, log: System.get_env("GRAPHQL_LOG") == "1"

config :phoenix, :generators,
  migration: true,
  binary_id: false

config :phoenix, :json_library, Jason

config :tzdata, :autoupdate, :disabled

import_config "#{Mix.env()}.exs"
