defmodule Timesup.StoredGameTest do
  use Timesup.DataCase
  alias Timesup.Game
  alias Timesup.StoredGame

  test "a game can be transformed into a stored game changeset, inserted and fetched back" do
    initial_game = game_fixture("id")
    stored_game = StoredGame.from_game(initial_game)

    assert %Ecto.Changeset{valid?: true} = stored_game

    Repo.insert!(stored_game)

    game =
      StoredGame
      |> Repo.get(initial_game.id)
      |> StoredGame.to_game()

    assert game == initial_game
  end

  test "a stored game can be updated" do
    game_fixture("id")
    |> StoredGame.from_game()
    |> Repo.insert!()

    game =
      StoredGame
      |> Repo.get("id")
      |> StoredGame.to_game()

    assert game.time_remaining == 29

    game
    |> Game.tick()
    |> StoredGame.from_game()
    |> Repo.update!()

    updated_game =
      StoredGame
      |> Repo.get("id")
      |> StoredGame.to_game()

    assert updated_game.time_remaining == 28
  end

  defp game_fixture(id) do
    Game.new(id)
    |> Game.add_player("kim")
    |> Game.add_player("cam")
    |> Game.add_player("etienne")
    |> Game.add_player("fab")
    |> Game.add_card("Turing", "kim")
    |> Game.add_card("Babar", "cam")
    |> Game.add_card("Gérard Holtz", "etienne")
    |> Game.add_card("Jean Claude Gaudin", "fab")
    |> Game.choose_team("kim", 0)
    |> Game.choose_team("cam", 0)
    |> Game.choose_team("etienne", 1)
    |> Game.choose_team("fab", 1)
    |> Game.start_game()
    |> Game.start_turn()
    |> Game.tick()
  end
end
