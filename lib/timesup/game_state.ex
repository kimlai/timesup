defmodule Timesup.GameState do
  alias __MODULE__

  @seconds_per_turn 30

  defstruct(
    id: nil,
    status: :deck_building,
    players: %{},
    deck: [],
    player_stack: [],
    playing: false,
    time_remaining: @seconds_per_turn
  )

  def new(id) do
    %GameState{id: id}
  end

  def add_player(%GameState{} = game, player) do
    %{
      game
      | players:
          Map.put_new(game.players, player, %{
            name: player,
            ready: false,
            cards: [],
            team: nil,
            points: 0
          })
    }
  end

  def get_players(%GameState{players: players}) do
    Map.values(players)
  end

  def add_card(%GameState{} = game, card, player) do
    %{
      game
      | players: Map.update!(game.players, player, fn p -> %{p | cards: p.cards ++ [card]} end)
    }
  end

  def get_player_cards(%GameState{players: players}, player) do
    players
    |> Map.get(player)
    |> Map.get(:cards)
  end

  def set_player_ready(%GameState{players: players} = game, player) do
    %{game | players: Map.update!(players, player, fn p -> %{p | ready: true} end)}
  end

  def player_ready?(%GameState{players: players}, player) do
    Map.get(players, player).ready
  end

  def all_players_ready?(%GameState{players: players}) do
    Enum.all?(players, fn {_, p} -> p.ready == true end)
  end

  def start_choosing_teams(%GameState{} = game) do
    %{game | status: :choosing_teams}
  end

  def choose_team(%GameState{} = game, player, team) do
    %{game | players: Map.update!(game.players, player, fn p -> %{p | team: team} end)}
  end

  def team_1(%GameState{players: players} = game) do
    players
    |> Map.values()
    |> Enum.filter(fn p -> p.team == :team_1 end)
  end

  def team_1_points(%GameState{} = game) do
    game
    |> team_1()
    |> Enum.map(fn p -> p.points end)
    |> Enum.sum()
  end

  def team_2(%GameState{players: players} = game) do
    players
    |> Map.values()
    |> Enum.filter(fn p -> p.team == :team_2 end)
  end

  def team_2_points(%GameState{} = game) do
    game
    |> team_2()
    |> Enum.map(fn p -> p.points end)
    |> Enum.sum()
  end

  def players_with_no_team(%GameState{players: players} = game) do
    players
    |> Map.values()
    |> Enum.filter(fn p -> p.team == nil end)
  end

  def start_game(%GameState{} = game) do
    %{
      game
      | status: :first_round,
        deck: Enum.flat_map(game.players, fn {_, p} -> p.cards end) |> Enum.shuffle(),
        player_stack: build_player_stack(team_1(game), team_2(game))
    }
  end

  def current_player(%GameState{player_stack: [head | _]}), do: head

  def current_card(%GameState{deck: []}), do: nil
  def current_card(%GameState{deck: [head | _]}), do: head

  def start_turn(%GameState{} = game) do
    %{game | playing: true}
  end

  def tick(%GameState{playing: false} = game), do: game

  def tick(%GameState{player_stack: [head | tail]} = game) do
    time_remaining = game.time_remaining - 1

    if time_remaining < 0 do
      %{game | time_remaining: @seconds_per_turn, playing: false, player_stack: tail ++ [head]}
    else
      %{game | time_remaining: time_remaining}
    end
  end

  def card_guessed(%GameState{deck: [_ | tail]} = game) do
    %{
      game
      | deck: tail,
        players:
          Map.update!(game.players, current_player(game).name, fn p ->
            %{p | points: p.points + 1}
          end),
        playing: tail != []
    }
  end

  defp build_player_stack(team_1, team_2) do
    cond do
      length(team_1) < length(team_2) ->
        build_stack(pad(team_1, team_2), team_2)

      length(team_1) > length(team_2) ->
        build_stack(pad(team_2, team_1), team_1)

      true ->
        build_stack(team_1, team_2)
    end
  end

  defp build_stack([], _), do: []

  defp build_stack([p | tail], team2) do
    [p | build_stack(team2, tail)]
  end

  # pad([1, 2], [3, 4, 5]) -> [1, 2, 1]
  defp pad(l1, l2), do: pad(l1, l2, l1)
  defp pad(_, [], _), do: []
  defp pad([], [_ | _] = l2, original_l1), do: pad(original_l1, l2)

  defp pad([head | tail_1], [_ | tail_2], original_l1) do
    [head | pad(tail_1, tail_2, original_l1)]
  end
end
