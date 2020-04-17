defmodule Timesup.GameState do
  alias __MODULE__

  defstruct(
    id: nil,
    status: :deck_building,
    players: %{},
    deck: [],
    player_stack: [],
    playing: false,
    time_remaining: 60,
    round: :round_1
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
            points: %{
              round_1: 0,
              round_2: 0,
              round_3: 0
            }
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

  def team_1(%GameState{} = game) do
    team(game, :team_1)
  end

  def team_2(%GameState{} = game) do
    team(game, :team_2)
  end

  defp team(%GameState{players: players} = game, team) do
    players
    |> Map.values()
    |> Enum.filter(fn p -> p.team == team end)
  end

  def team_1_points(%GameState{} = game) do
    team_points(game, :team_1)
  end

  def team_2_points(%GameState{} = game) do
    team_points(game, :team_2)
  end

  defp team_points(%GameState{} = game, team) do
    game
    |> team(team)
    |> Enum.map(fn p -> p.points end)
    |> Enum.reduce(fn x, acc ->
      %{
        round_1: acc.round_1 + x.round_1,
        round_2: acc.round_2 + x.round_2,
        round_3: acc.round_3 + x.round_3
      }
    end)
  end

  def players_with_no_team(%GameState{players: players} = game) do
    players
    |> Map.values()
    |> Enum.filter(fn p -> p.team == nil end)
  end

  def start_game(%GameState{} = game) do
    %{
      game
      | status: :game_started,
        deck: shuffle_deck(game),
        player_stack: build_player_stack(team_1(game), team_2(game))
    }
  end

  def shuffle_deck(%GameState{players: players} = game) do
    players
    |> Enum.flat_map(fn {_, p} -> p.cards end)
    |> Enum.shuffle()
  end

  def current_player(%GameState{player_stack: [head | _]}), do: head

  def current_card(%GameState{deck: []}), do: nil
  def current_card(%GameState{deck: [head | _]}), do: head

  def start_turn(%GameState{} = game) do
    %{game | playing: true}
  end

  def seconds_per_turn(:round_1), do: 60
  def seconds_per_turn(_), do: 30

  def tick(%GameState{playing: false} = game), do: game

  def tick(%GameState{} = game) do
    time_remaining = game.time_remaining - 1

    if time_remaining < 0 do
      end_turn(game)
    else
      %{game | time_remaining: time_remaining}
    end
  end

  defp end_turn(%GameState{player_stack: [head | tail]} = game) do
    %{
      game
      | time_remaining: seconds_per_turn(game.round),
        playing: false,
        player_stack: tail ++ [head]
    }
  end

  def card_guessed(%GameState{deck: [_ | []]} = game) do
    game
    |> add_point()
    |> end_turn()
    |> end_round()
  end

  def card_guessed(%GameState{deck: [_ | tail]} = game) do
    %{game | deck: tail}
    |> add_point()
  end

  defp add_point(game) do
    %{
      game
      | players:
          Map.update!(game.players, current_player(game).name, fn p ->
            %{p | points: Map.update!(p.points, game.round, &(&1 + 1))}
          end)
    }
  end

  def end_round(game) do
    %{
      game
      | round: next_round(game.round),
        deck: shuffle_deck(game),
        time_remaining: seconds_per_turn(next_round(game.round))
    }
  end

  def game_over?(game), do: game.round == nil

  defp next_round(:round_1), do: :round_2
  defp next_round(:round_2), do: :round_3
  defp next_round(:round_3), do: nil

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

  def fixture(id) do
    %GameState{
      id: id,
      status: :deck_building,
      players: %{
        "kim" => %{
          name: "kim",
          ready: true,
          cards: ["Roger Rabbit", "Batman"],
          team: :team_1,
          points: %{
            round_1: 0,
            round_2: 0,
            round_3: 0
          }
        },
        "julie" => %{
          name: "julie",
          ready: true,
          cards: ["Superman", "Spiderman"],
          team: :team_1,
          points: %{
            round_1: 0,
            round_2: 0,
            round_3: 0
          }
        },
        "louis" => %{
          name: "louis",
          ready: true,
          cards: ["Shakira", "Beyoncé"],
          team: :team_1,
          points: %{
            round_1: 0,
            round_2: 0,
            round_3: 0
          }
        },
        "etienne" => %{
          name: "etienne",
          ready: true,
          cards: ["Bourdieu", "Mendeleiev"],
          team: :team_2,
          points: %{
            round_1: 0,
            round_2: 0,
            round_3: 0
          }
        },
        "fab" => %{
          name: "fab",
          ready: true,
          cards: ["Otis Redding", "Charles Mingus"],
          team: :team_2,
          points: %{
            round_1: 0,
            round_2: 0,
            round_3: 0
          }
        },
        "cam" => %{
          name: "cam",
          ready: true,
          cards: ["Anaïs", "Benabar"],
          team: :team_2,
          points: %{
            round_1: 0,
            round_2: 0,
            round_3: 0
          }
        }
      },
      deck: [],
      player_stack: [],
      playing: false,
      time_remaining: 60
    }
    |> start_game()
  end
end
