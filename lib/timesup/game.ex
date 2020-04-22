defmodule Timesup.Game do
  alias __MODULE__

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
    last_card_guessed: nil,
    teams: [[], []]
  )

  def new(id) do
    %Game{id: id}
  end

  def add_player(%Game{} = game, player) do
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

  def get_players(%Game{players: players}) do
    Map.values(players)
  end

  def add_card(%Game{} = game, card, player) do
    %{
      game
      | players: Map.update!(game.players, player, fn p -> %{p | cards: p.cards ++ [card]} end)
    }
  end

  def get_player_cards(%Game{players: players}, player) do
    players
    |> Map.get(player)
    |> Map.get(:cards)
  end

  def number_of_cards(%Game{players: players}) do
    players
    |> Enum.flat_map(fn {_, p} -> p.cards end)
    |> length()
  end

  def set_player_ready(%Game{players: players} = game, player) do
    %{game | players: Map.update!(players, player, fn p -> %{p | ready: true} end)}
  end

  def player_ready?(%Game{players: players}, player) do
    Map.get(players, player).ready
  end

  def all_players_ready?(%Game{players: players}) do
    Enum.all?(players, fn {_, p} -> p.ready == true end)
  end

  def start_choosing_teams(%Game{} = game) do
    %{game | status: :choosing_teams}
  end

  def choose_team(%Game{teams: teams} = game, player, team_index)
      when is_integer(team_index) and 0 <= team_index and team_index < length(teams) do
    %{
      game
      | teams:
          teams
          |> remove_from_all_teams(player)
          |> List.replace_at(team_index, Enum.at(teams, team_index) ++ [player])
    }
  end

  defp remove_from_all_teams(teams, player) do
    Enum.map(teams, fn team -> Enum.reject(team, fn p -> p == player end) end)
  end

  def team(%Game{players: players} = game, team_index) do
    game.teams
    |> Enum.at(team_index)
    |> Enum.map(fn p -> Map.get(players, p) end)
  end

  def team_points(%Game{} = game, team_index) do
    game
    |> team(team_index)
    |> Enum.map(fn p -> p.points end)
    |> Enum.reduce(%{round_1: 0, round_2: 0, round_3: 0}, fn x, acc ->
      %{
        round_1: acc.round_1 + x.round_1,
        round_2: acc.round_2 + x.round_2,
        round_3: acc.round_3 + x.round_3
      }
    end)
  end

  def players_with_no_team(%Game{players: players} = game) do
    players_with_team = List.flatten(game.teams)

    players
    |> Map.values()
    |> Enum.reject(fn p -> Enum.member?(players_with_team, p.name) end)
  end

  def start_game(%Game{} = game) do
    %{
      game
      | status: :game_started,
        deck: shuffle_deck(game),
        player_stack: Enum.reject(game.teams, fn t -> t == [] end)
    }
  end

  def shuffle_deck(%Game{players: players}) do
    players
    |> Enum.flat_map(fn {_, p} -> p.cards end)
    |> Enum.shuffle()
  end

  def current_player(%Game{player_stack: [[head | _] | _]}), do: head

  def current_card(%Game{deck: []}), do: nil
  def current_card(%Game{deck: [head | _]}), do: head

  def start_turn(%Game{} = game) do
    %{game | playing: true, last_card_guessed: nil}
  end

  def tick(%Game{playing: false} = game), do: game

  def tick(%Game{} = game) do
    time_remaining = game.time_remaining - 1

    if time_remaining < 0 do
      end_turn(game)
    else
      %{game | time_remaining: time_remaining}
    end
  end

  defp end_turn(%Game{} = game) do
    [[last_player | other_players] | other_teams] = game.player_stack
    [last_card | other_cards] = game.deck

    %{
      game
      | time_remaining: @seconds_per_turn,
        playing: false,
        player_stack: other_teams ++ [other_players ++ [last_player]],
        deck: other_cards ++ [last_card]
    }
  end

  def card_guessed(%Game{deck: [card | []]} = game) do
    game
    |> add_point(card)
    |> end_turn()
    |> end_round()
  end

  def card_guessed(%Game{deck: [card | tail]} = game) do
    %{game | deck: tail}
    |> add_point(card)
  end

  defp add_point(game, card) do
    %{
      game
      | last_card_guessed: card,
        players:
          Map.update!(game.players, current_player(game), fn p ->
            %{p | points: Map.update!(p.points, game.round, &(&1 + 1))}
          end)
    }
  end

  def pass_card(%Game{deck: [head | tail]} = game) do
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

  def skip_player(%Game{player_stack: [[head | tail] | other_teams]} = game, player)
      # in case multiple players click the skip button at the same time
      when head == player do
    %{game | player_stack: [tail ++ [head] | other_teams]}
  end

  def skip_player(%Game{} = game), do: game

  defp next_round(:round_1), do: :round_2
  defp next_round(:round_2), do: :round_3
  defp next_round(:round_3), do: nil

  def start_round(%Game{} = game) do
    %{game | show_round_intro: false}
  end

  def delete_card(%Game{players: players} = game, player, index) do
    %{
      game
      | players:
          Map.update!(players, player, fn p -> %{p | cards: List.delete_at(p.cards, index)} end)
    }
  end

  def fixture(id) do
    %Game{
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
