use Mix.Config

config :talk, TalkWeb.Endpoint,
  url: [host: "localhost"],
  http: [port: 7000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false

# main database
config :talk, Talk.Repo,
  username: "postgres",
  password: "postgres",
  database: "talk_dev",
  hostname: "localhost",
  pool_size: 5,
  timeout: 90_000,
  log: String.to_atom(System.get_env("SQL_LOG")) || false

# sapien database
config :talk, Talk.SapienRepo,
  username: "sapien",
  password: "sapien",
  database: "sapien",
  hostname: "localhost",
  pool_size: 5,
  timeout: 90_000,
  log: String.to_atom(System.get_env("SQL_LOG")) || false

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime
