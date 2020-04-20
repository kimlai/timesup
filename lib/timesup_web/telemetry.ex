defmodule TimesupWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),

      # Database Time Metrics
      summary("timesup.repo.query.total_time", unit: {:native, :millisecond}),
      summary("timesup.repo.query.decode_time", unit: {:native, :millisecond}),
      summary("timesup.repo.query.query_time", unit: {:native, :millisecond}),
      summary("timesup.repo.query.queue_time", unit: {:native, :millisecond}),
      summary("timesup.repo.query.idle_time", unit: {:native, :millisecond})
    ]
  end

  defp periodic_measurements do
    # A module, function and arguments to be invoked periodically.
    # This function must call :telemetry.execute/3 and a metric must be added above.
    # {<%= web_namespace %>, :count_users, []}
    []
  end
end
