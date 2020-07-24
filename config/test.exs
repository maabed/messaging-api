use Mix.Config

config :talk, Talk.Repo,
  username: "postgres",
  password: "postgres",
  database: "talk_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :talk, TalkWeb.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn
