defmodule Timesup.Game do
  use GenServer
  alias Timesup.GameState

  # Client

  def start_link(options) do
    [name: {:via, Registry, {Timesup.GameRegistry, game_id}}] = options
    GenServer.start_link(__MODULE__, GameState.new(game_id), options)
  end

  @impl true
  def init(game) do
    {:ok, game}
  end

  def game(game_id) do
    GenServer.call(via_tuple(game_id), :game)
  end

  def join(game_id, username) do
    GenServer.call(via_tuple(game_id), {:join, username})
  end

  def add_card(game_id, card, player) do
    GenServer.call(via_tuple(game_id), {:add_card, card, player})
  end

  def set_player_ready(game_id, player) do
    GenServer.cast(via_tuple(game_id), {:set_player_ready, player})
  end

  def start_choosing_teams(game_id) do
    GenServer.cast(via_tuple(game_id), {:start_choosing_teams})
  end

  def choose_team(game_id, player, team) do
    GenServer.cast(via_tuple(game_id), {:choose_team, player, team})
  end

  def start_game(game_id) do
    GenServer.cast(via_tuple(game_id), {:start_game})
  end

  def start_turn(game_id) do
    GenServer.cast(via_tuple(game_id), {:start_turn})
  end

  def card_guessed(game_id) do
    GenServer.cast(via_tuple(game_id), {:card_guessed})
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
  def handle_call({:join, username}, _from, game) do
    game = GameState.add_player(game, username)
    {:reply, game, game}
  end

  @impl true
  def handle_call({:add_card, card, player}, _from, game) do
    game = GameState.add_card(game, card, player)
    {:reply, game, game}
  end

  @impl true
  def handle_cast({:set_player_ready, player}, game) do
    {:noreply, GameState.set_player_ready(game, player)}
  end

  @impl true
  def handle_cast({:start_choosing_teams}, game) do
    {:noreply, GameState.start_choosing_teams(game)}
  end

  @impl true
  def handle_cast({:choose_team, player, team}, game) do
    {:noreply, GameState.choose_team(game, player, team)}
  end

  @impl true
  def handle_cast({:start_game}, game) do
    {:noreply, GameState.start_game(game)}
  end

  @impl true
  def handle_cast({:start_turn}, game) do
    Process.send_after(self(), :tick, 1000)
    {:noreply, GameState.start_turn(game)}
  end

  @impl true
  def handle_cast({:card_guessed}, game) do
    {:noreply, GameState.card_guessed(game)}
  end

  @impl true
  def handle_info(:tick, game) do
    game = GameState.tick(game)

    if game.playing do
      Process.send_after(self(), :tick, 1000)
    end

    Phoenix.PubSub.broadcast!(Timesup.PubSub, game.id, :update)

    {:noreply, game}
  end
end
