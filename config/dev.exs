import Config

config :talk, TalkWeb.Endpoint,
  url: [host: "localhost"],
  http: [port: 7000],
  debug_errors: true,
  code_reloader: true
  # check_origin: false

config :talk, Talk.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "sapien",
  password: "sapien",
  database: "sapien",
  hostname: "localhost",
  pool_size: 10,
  log: :debug
  # loggers: [{LoggerJSON.Ecto, :log, [:info]}] # # new logs using luki and LoggerJSON

config :logger, :console,
  level: :info,
  format: "[$level] $message\n",
  truncate: :infinity

config :phoenix, :stacktrace_depth, 20

config :phoenix, :plug_init_mode, :runtime

# new logs using luki
# config :phoenix, :logger, :warn
