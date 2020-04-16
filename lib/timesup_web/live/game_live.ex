defmodule TimesupWeb.GameLive do
  use Phoenix.LiveView, layout: {TimesupWeb.LayoutView, "live.html"}

  def mount(%{"id" => game_id}, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Timesup.PubSub, game_id)
    {:ok, assign_game(socket, game_id)}
  end

  defp assign_game(socket, game_id) do
    socket
    |> assign(game_id: game_id)
    |> assign_game()
  end

  defp assign_game(%{assigns: %{game_id: game_id}} = socket) do
    game = Timesup.Game.game(game_id)
    assign(socket, game: game)
  end

  def render(assigns) do
    Phoenix.View.render(TimesupWeb.PageView, "game.html", assigns)
  end

  def handle_info("update", socket) do
    {:noreply, assign_game(socket)}
  end
end
