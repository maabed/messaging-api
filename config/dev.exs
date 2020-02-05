import Config

config :talk, TalkWeb.Endpoint,
  url: [host: "localhost"],
  http: [port: 7000],
  debug_errors: true,
  code_reloader: true
  # check_origin: false

config :talk, Talk.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "sapien",
  hostname: "localhost",
  pool_size: 10,
  log: :debug

config :logger, :console,
  format: "[$level] $message\n",
  truncate: :infinity

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime
