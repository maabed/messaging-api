use Mix.Config

config :talk, TalkWeb.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: System.get_env("HOST")],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  debug_errors: true,
  code_reloader: false,
  check_origin: ["//localhost", "//*.sapien.network", "//sapien-chat.herokuapp.com"]

config :talk, Talk.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "20"),
  ssl: true,
  timeout: 240_000,
  log: String.to_atom(System.get_env("SQL_LOG")) || false

config :talk, Talk.SapienRepo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("SAPIEN_DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("SAPIEN_POOL_SIZE") || "10"),
  ssl: true,
  timeout: 240_000,
  log: String.to_atom(System.get_env("SQL_LOG")) || false

config :talk,
  basic_auth: [
    username: System.get_env("BASIC_AUTH_USERNAME"),
    password: System.get_env("BASIC_AUTH_PASSWORD"),
    realm: "GraphiQL Endpoint"
  ]

config :logger, level: :info

import_config "prod.secret.exs"
