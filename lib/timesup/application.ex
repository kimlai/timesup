defmodule Timesup.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Timesup.Repo,
      TimesupWeb.Telemetry,
      TimesupWeb.Endpoint,
      TimesupWeb.Presence,
      {Registry, keys: :unique, name: Timesup.GameRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: Timesup.GameSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Timesup.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TimesupWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
