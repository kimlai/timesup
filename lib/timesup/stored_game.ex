defmodule Timesup.StoredGame do
  @moduledoc """
  Serves as a translation layer between the Game State and the database.

  Since so much of the game state is internal to the application, I don't
  want to bother with schemas, embedded schemas and all that. It would
  clutter the GameState code, which is where all the important logic is.
  It makes for a very ugly module, which could be *cleaner* with Ecto types,
  but not really *better*.
  """
  use Ecto.Schema
  alias Timesup.StoredGame
  alias Timesup.GameState

  @primary_key {:id, :string, []}
  schema "games" do
    field(:deck, {:array, :string})
    field(:players, :map)
    field(:status, :string)
    field(:round, :string)

    timestamps()
  end

  def from_game_state(%GameState{} = game) do
    %StoredGame{
      id: game.id,
      deck: game.deck,
      players: game.players,
      status: Atom.to_string(game.status),
      round: Atom.to_string(game.round)
    }
  end

  def to_game_state(%StoredGame{} = game) do
    state = %GameState{
      id: game.id,
      deck: game.deck,
      players: Enum.map(game.players, &parse_player/1) |> Map.new(),
      status: parse_status(game.status),
      round: parse_round(game.round)
    }

    %{state | player_stack: GameState.build_player_stack(state)}
  end

  defp parse_player(
         {k,
          %{
            "cards" => cards,
            "name" => name,
            "points" => %{"round_1" => round_1, "round_2" => round_2, "round_3" => round_3},
            "ready" => ready?,
            "team" => team
          }}
       ) do
    {k,
     %{
       cards: cards,
       name: name,
       points: %{round_1: round_1, round_2: round_2, round_3: round_3},
       ready: ready?,
       team: parse_team(team)
     }}
  end

  defp parse_status("deck_building"), do: :deck_building
  defp parse_status("choosing_teams"), do: :choosing_teams
  defp parse_status("game_started"), do: :game_started

  defp parse_team("team_1"), do: :team_1
  defp parse_team("team_2"), do: :team_2
  defp parse_team(nil), do: nil

  defp parse_round("round_1"), do: :round_1
  defp parse_round("round_2"), do: :round_2
  defp parse_round("round_3"), do: :round_3
  defp parse_round(nil), do: nil
end