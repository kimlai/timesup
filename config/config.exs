# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :timesup,
  ecto_repos: [Timesup.Repo]

# Configures the endpoint
config :timesup, TimesupWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "eYvSqlTXjV9r+cy7zI3P/JvXlBhLuFG5fqR0moaXxpPqZ5AbSqMqPl8r1EGvh96A",
  render_errors: [view: TimesupWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Timesup.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "SECRET_SALT"
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
