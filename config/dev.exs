use Mix.Config

config :talk, TalkWeb.Endpoint,
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
  show_sensitive_data_on_connection_error: true,
  pool_size: 40,
  log: String.to_atom(System.get_env("SQL_LOG")) || :info

# sapien database
config :talk, Talk.SapienRepo,
  username: "postgres",
  password: "postgres",
  database: "sapien",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10,
  log: String.to_atom(System.get_env("SQL_LOG")) || :info

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime

import_config "dev.secret.exs"
