# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :talk,
  ecto_repos: [Talk.Repo],
  generators: [binary_id: true]

# Configures the endpoint
config :talk, TalkWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "IXE7RLjiC2vuP8lx8AxxWJr3xulxnEqCCH/s80Y7p1fL7zW8lA/WOOx2qigjw5eX",
  render_errors: [view: TalkWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Talk.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
