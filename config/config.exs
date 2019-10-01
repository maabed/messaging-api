use Mix.Config

config :talk,
  ecto_repos: [Talk.Repo],
  env: Mix.env(),
  origins: String.split("//127.0.0.1 //localhost //*.sapien.network //sapien-chat.herokuapp.com", ~r{\s+}, trim: true),
  jwt_aud: String.split("sapien.network  beta.sapien.network  talk.sapien.network  notifier.sapien.network", ~r{\s+}, trim: true)

config :talk, Talk.Repo, migration_timestamps: [type: :utc_datetime_usec]

config :talk, TalkWeb.Endpoint,
  url: [host: System.get_env("HOST")],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: TalkWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Talk.PubSub, adapter: Phoenix.PubSub.PG2],
  watchers: [],
  check_origin: String.split("//127.0.0.1 //localhost //*.sapien.network //sapien-chat.herokuapp.com", ~r{\s+}, trim: true)

config :talk, TalkWeb.Auth,
  issuer: "sapien",
  ttl: {120, :days},
  allowed_algos: ["RS256"],
  allowed_drift: 2000,
  verify_issuer: true,
  secret_fetcher: TalkWeb.Auth.SecretFetcher

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
