defmodule Timesup.GameTest do
  use ExUnit.Case
  alias Timesup.Game

  test "people can play (critical happy path)" do
    game =
      Game.new("id")
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

    assert game.round == :round_1
    assert [["kim", "cam"], ["etienne", "fab"]] = game.player_stack
    assert Game.current_player(game) == "kim"

    game = Enum.reduce(30..0, game, fn _x, game -> Game.tick(game) end)

    assert Game.current_player(game) == "etienne"

    game = Game.start_turn(game)
    [first, second | _] = game.deck
    assert Game.current_card(game) == first

    {:ok, game} = Game.pass_card(game, first)
    assert Game.current_card(game) == second

    {:ok, game} =
      Enum.reduce(1..4, {:ok, game}, fn _x, {:ok, game} ->
        Game.card_guessed(game, Game.current_card(game))
      end)

    assert game.round == :round_2
    assert Game.current_player(game) == "cam"

    {:ok, game} =
      Enum.reduce(1..4, {:ok, game}, fn _x, {:ok, game} ->
        Game.card_guessed(game, Game.current_card(game))
      end)

    assert game.round == :round_3
    assert Game.current_player(game) == "fab"

    {:ok, game} =
      Enum.reduce(1..4, {:ok, game}, fn _x, {:ok, game} ->
        Game.card_guessed(game, Game.current_card(game))
      end)

    assert game.round == nil
  end

  test "no duplicate players in a team" do
    game =
      Game.new("id")
      |> Game.add_player("kim")
      |> Game.choose_team("kim", 0)
      |> Game.choose_team("kim", 0)

    assert game.teams == [["kim"], []]
  end
end
