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

  def get_game(game_id) do
    GenServer.call(via_tuple(game_id), :game)
  end

  def join(game_id, username) do
    GenServer.call(via_tuple(game_id), {:join, username})
  end

  def add_card(game_id, card, player) do
    GenServer.call(via_tuple(game_id), {:add_card, card, player})
  end

  def set_player_ready(game_id, player) do
    GenServer.call(via_tuple(game_id), {:set_player_ready, player})
  end

  def start_choosing_teams(game_id) do
    GenServer.call(via_tuple(game_id), {:start_choosing_teams})
  end

  def choose_team(game_id, player, team) do
    GenServer.call(via_tuple(game_id), {:choose_team, player, team})
  end

  def start_game(game_id) do
    GenServer.call(via_tuple(game_id), {:start_game})
  end

  def start_turn(game_id) do
    GenServer.call(via_tuple(game_id), {:start_turn})
  end

  def card_guessed(game_id) do
    GenServer.call(via_tuple(game_id), {:card_guessed})
  end

  def pass_card(game_id) do
    GenServer.call(via_tuple(game_id), {:pass_card})
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
  def handle_call({:set_player_ready, player}, _from, game) do
    game = GameState.set_player_ready(game, player)
    {:reply, game, game}
  end

  @impl true
  def handle_call({:start_choosing_teams}, _from, game) do
    game = GameState.start_choosing_teams(game)
    {:reply, game, game}
  end

  @impl true
  def handle_call({:choose_team, player, team}, _from, game) do
    game = GameState.choose_team(game, player, team)
    {:reply, game, game}
  end

  @impl true
  def handle_call({:start_game}, _from, game) do
    game = GameState.start_game(game)
    {:reply, game, game}
  end

  @impl true
  def handle_call({:start_turn}, _from, game) do
    Process.send_after(self(), :tick, 1000)
    game = GameState.start_turn(game)
    {:reply, game, game}
  end

  @impl true
  def handle_call({:card_guessed}, _from, game) do
    game = GameState.card_guessed(game)
    {:reply, game, game}
  end

  @impl true
  def handle_call({:pass_card}, _from, game) do
    game = GameState.pass_card(game)
    {:reply, game, game}
  end

  @impl true
  def handle_info(:tick, game) do
    game = GameState.tick(game)

    if game.playing do
      Process.send_after(self(), :tick, 1000)
    end

    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})

    {:noreply, game}
  end
end
