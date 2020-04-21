defmodule Timesup.GameState do
  alias __MODULE__
  alias Timesup.ListExtra

  @seconds_per_turn 30

  defstruct(
    id: nil,
    status: :deck_building,
    players: %{},
    deck: [],
    player_stack: [],
    playing: false,
    time_remaining: @seconds_per_turn,
    round: :round_1,
    show_round_intro: true,
    last_card_guessed: nil
  )

  def new(id) do
    %GameState{id: id}
  end

  def add_player(%GameState{} = game, player) do
    player_name = String.trim(player)

    %{
      game
      | players:
          Map.put_new(game.players, player_name, %{
            name: player_name,
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

  def number_of_cards(%GameState{players: players}) do
    players
    |> Enum.flat_map(fn {_, p} -> p.cards end)
    |> length()
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
    |> Enum.reduce(%{round_1: 0, round_2: 0, round_3: 0}, fn x, acc ->
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
        player_stack: build_player_stack(game)
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
    %{game | playing: true, last_card_guessed: nil}
  end

  def tick(%GameState{playing: false} = game), do: game

  def tick(%GameState{} = game) do
    time_remaining = game.time_remaining - 1

    if time_remaining < 0 do
      end_turn(game)
    else
      %{game | time_remaining: time_remaining}
    end
  end

  defp end_turn(%GameState{} = game) do
    [last_player | other_players] = game.player_stack
    [last_card | other_cards] = game.deck

    %{
      game
      | time_remaining: @seconds_per_turn,
        playing: false,
        player_stack: other_players ++ [last_player],
        deck: other_cards ++ [last_card]
    }
  end

  def card_guessed(%GameState{deck: [card | []]} = game) do
    game
    |> add_point(card)
    |> end_turn()
    |> end_round()
  end

  def card_guessed(%GameState{deck: [card | tail]} = game) do
    %{game | deck: tail}
    |> add_point(card)
  end

  defp add_point(game, card) do
    %{
      game
      | last_card_guessed: card,
        players:
          Map.update!(game.players, current_player(game).name, fn p ->
            %{p | points: Map.update!(p.points, game.round, &(&1 + 1))}
          end)
    }
  end

  def pass_card(%GameState{deck: [head | tail]} = game) do
    %{game | deck: tail ++ [head]}
  end

  def end_round(game) do
    %{
      game
      | round: next_round(game.round),
        deck: shuffle_deck(game),
        time_remaining: @seconds_per_turn,
        show_round_intro: true
    }
  end

  def game_over?(game), do: game.round == nil

  defp next_round(:round_1), do: :round_2
  defp next_round(:round_2), do: :round_3
  defp next_round(:round_3), do: nil

  def build_player_stack(%GameState{} = game) do
    {team_1, team_2} = ListExtra.pad(team_1(game), team_2(game))
    build_stack(team_1, team_2)
  end

  defp build_stack(team1, []), do: team1
  defp build_stack([], team2), do: team2

  defp build_stack([p | tail], team2) do
    [p | build_stack(team2, tail)]
  end

  def start_round(%GameState{} = game) do
    %{game | show_round_intro: false}
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
      time_remaining: @seconds_per_turn
    }
    |> start_game()
  end
end
