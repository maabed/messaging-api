import Config

config :talk, TalkWeb.Endpoint,
  http: [compress: true, port: {:system, "PORT"}],
  url: [host: System.get_env("HOST")],
  server: true

# config :talk, Talk.Repo, ssl: false

config :logger, level: :info
