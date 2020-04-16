defmodule Timesup.Game do
  use GenServer

  # Client

  def start_link(options) do
    GenServer.start_link(__MODULE__, %{players: []}, options)
  end

  @impl true
  def init(game) do
    {:ok, game}
  end

  def game(game_id) do
    GenServer.call(via_tuple(game_id), :game)
  end

  def join(game_id, username) do
    GenServer.cast(via_tuple(game_id), {:join, username})
  end

  defp via_tuple(game_id) do
    {:via, Registry, {Timesup.GameRegistry, game_id}}
  end

  # Server (callbacks)

  @impl true
  def handle_call(:game, _from, game) do
    {:reply, game, game}
  end

  @impl true
  def handle_cast({:join, username}, game) do
    {:noreply, %{game | players: game.players ++ [username]}}
  end
end
