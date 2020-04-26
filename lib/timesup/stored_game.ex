defmodule Timesup.StoredGame do
  @moduledoc """
  Serves as a translation layer between in memory Game state and the database.

  Since so much of the game state is internal to the application, I don't
  want to bother with schemas, embedded schemas and all that. It would
  clutter the Game code, which is where all the important logic is.
  It makes for a very ugly module, which could be *cleaner* with Ecto types,
  but not really *better*.
  """
  use Ecto.Schema
  alias Timesup.StoredGame
  alias Timesup.Game
  import Ecto.Changeset

  @primary_key {:id, :string, []}
  schema "games" do
    field(:deck, {:array, :string})
    field(:players, :map)
    field(:status, :string)
    field(:round, :string)
    field(:teams, :map)
    field(:player_stack, :map)
    field(:playing, :boolean)
    field(:time_remaining, :integer)
    field(:show_round_intro, :boolean)
    field(:last_card_guessed, :string)

    timestamps()
  end

  def from_game(%Game{} = game) do
    change(
      %StoredGame{id: game.id},
      deck: game.deck,
      players: game.players,
      status: Atom.to_string(game.status),
      round: Atom.to_string(game.round),
      teams: list_to_map(game.teams),
      player_stack: list_to_map(game.player_stack),
      playing: game.playing,
      show_round_intro: game.show_round_intro,
      time_remaining: game.time_remaining,
      last_card_guessed: game.last_card_guessed
    )
  end

  def to_game(%StoredGame{} = game) do
    %Game{
      id: game.id,
      deck: game.deck,
      players: Enum.map(game.players, &parse_player/1) |> Map.new(),
      status: parse_status(game.status),
      round: parse_round(game.round),
      teams: game.teams |> Map.values(),
      player_stack: game.player_stack |> Map.values() |> Enum.reject(fn t -> t == [] end),
      playing: game.playing,
      show_round_intro: game.show_round_intro,
      time_remaining: game.time_remaining,
      last_card_guessed: game.last_card_guessed
    }
  end

  defp parse_player(
         {k,
          %{
            "cards" => cards,
            "name" => name,
            "points" => %{"round_1" => round_1, "round_2" => round_2, "round_3" => round_3},
            "ready" => ready?
          }}
       ) do
    {k,
     %{
       cards: cards,
       name: name,
       points: %{round_1: round_1, round_2: round_2, round_3: round_3},
       ready: ready?
     }}
  end

  # PostgreSQL does not support multidimmensional arrays where the inner arrays have different lengths
  # so we need to store them as jsonb
  defp list_to_map(list) do
    list
    |> Enum.with_index()
    |> Enum.map(fn {k, v} -> {v, k} end)
    |> Map.new()
  end

  defp parse_status("deck_building"), do: :deck_building
  defp parse_status("choosing_teams"), do: :choosing_teams
  defp parse_status("game_started"), do: :game_started

  defp parse_round("round_1"), do: :round_1
  defp parse_round("round_2"), do: :round_2
  defp parse_round("round_3"), do: :round_3
  defp parse_round("nil"), do: nil
  defp parse_round(nil), do: nil
end
