use Mix.Config

config :talk, TalkWeb.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: System.get_env("HOST")],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  debug_errors: true,
  code_reloader: false,
  check_origin: ["//localhost", "//*.sapien.network", "//sapien-chat.herokuapp.com"]

config :talk, TalkWeb.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "18"),
  ssl: true,
  log: String.to_atom(System.get_env("SQL_LOG")) || false

config :talk, TalkWeb.Guardian,
  issuer: "sapien",
  allowed_algos: ["ES256"],
  secret_key: System.get_env("JWT_PUBLIC_KEY")

config :logger, level: :info

import_config "prod.secret.exs"
