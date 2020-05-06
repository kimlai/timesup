defmodule TimesupWeb.PageView do
  use TimesupWeb, :view
  alias Timesup.Game

  def game_summary(%Game{} = game) do
    game.teams
    |> Enum.with_index()
    |> Enum.map(fn {_, index} -> team_summary(game, index) end)
    |> Enum.sort_by(& &1.total, :desc)
  end

  def team_summary(game, i) do
    %{
      number: i + 1,
      players: Game.team(game, i),
      points: Game.team_points(game, i),
      total: Game.team_points(game, i) |> Map.values() |> Enum.sum()
    }
  end
end
