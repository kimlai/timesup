defmodule Timesup.StartServersTask do
  @moduledoc """
  A simple task responsible for starting all GameServers when the
  application starts.

  It loads existing games from the database (only games that were updated
  in the last 24 hours) and starts a `GameServer` for each one.
  """
  use Task, restart: :transient
  import Ecto.Query
  alias Timesup.StoredGame
  alias Timesup.Repo
  alias Timesup.GameServer

  def start_link(_) do
    Task.start_link(__MODULE__, :run, [])
  end

  def run() do
    StoredGame
    |> where([game], game.updated_at > ago(1, "day"))
    |> select([game], game.id)
    |> Repo.all()
    |> Enum.map(fn id ->
      DynamicSupervisor.start_child(
        Timesup.GameSupervisor,
        {GameServer, name: {:via, Registry, {Timesup.GameRegistry, id}}}
      )
    end)
  end
end
