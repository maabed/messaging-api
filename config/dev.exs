use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :talk, TalkWeb.Endpoint,
  http: [port: 7000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

# main database
config :talk, Talk.Repo,
  username: "postgres",
  password: "postgres",
  database: "talk_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 40

# sapien database
config :talk, Talk.SapienRepo,
  username: "postgres",
  password: "postgres",
  database: "sapien",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

config :absinthe,
  log: System.get_env("GRAPHQL_LOG") == "1"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
