defmodule Timesup.Repo do
  use Ecto.Repo,
    otp_app: :timesup,
    adapter: Ecto.Adapters.Postgres
end
