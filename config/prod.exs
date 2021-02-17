import Config

config :talk, TalkWeb.Endpoint,
  http: [compress: true, port: {:system, "PORT"}],
  url: [host: System.get_env("HOST")],
  load_from_system_env: true,
  server: true

# config :talk, Talk.Repo, ssl: false

# config :talk, Talk.Repo,
#   adapter: Ecto.Adapters.Postgres,
#   timeout: 60_000,
#   queue_target: 10_000,
#   queue_interval: 60_000,
#   ownership_timeout: 150_000

config :logger, level: :error
