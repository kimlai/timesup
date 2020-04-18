defmodule TimesupWeb.GameLive do
  use Phoenix.LiveView, layout: {TimesupWeb.LayoutView, "live.html"}

  def mount(%{"id" => game_id}, %{"current_user" => user}, socket) do
    if connected?(socket), do: TimesupWeb.Endpoint.subscribe(game_id)

    game =
      try do
        Timesup.Game.get_game(game_id)
      catch
        # most likely a new deployment destroyed the process
        :exit, _ ->
          nil
      end

    socket =
      socket
      |> assign(current_user: user)
      |> assign(game: game)

    {:ok, socket}
  end

  def render(assigns) do
    if assigns.game == nil do
      Phoenix.View.render(TimesupWeb.PageView, "404.html", assigns)
    else
      case assigns.game.status do
        :deck_building ->
          Phoenix.View.render(TimesupWeb.PageView, "deck_building.html", assigns)

        :choosing_teams ->
          Phoenix.View.render(TimesupWeb.PageView, "choose_teams.html", assigns)

        :game_started ->
          Phoenix.View.render(TimesupWeb.PageView, "game_started.html", assigns)
      end
    end
  end

  def handle_event("add_card", %{"card" => %{"name" => name}}, %{assigns: assigns} = socket) do
    {:noreply,
     assign(socket, :game, Timesup.Game.add_card(assigns.game.id, name, assigns.current_user))}
  end

  def handle_event("set_player_ready", %{}, %{assigns: assigns} = socket) do
    game = Timesup.Game.set_player_ready(assigns.game.id, assigns.current_user)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, assign(socket, game: game)}
  end

  def handle_event("start_choosing_teams", %{}, %{assigns: assigns} = socket) do
    game = Timesup.Game.start_choosing_teams(assigns.game.id)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, assign(socket, game: game)}
  end

  def handle_event("choose_team_1", %{}, socket) do
    choose_team(:team_1, socket)
  end

  def handle_event("choose_team_2", %{}, socket) do
    choose_team(:team_2, socket)
  end

  def handle_event("start_game", %{}, %{assigns: assigns} = socket) do
    game = Timesup.Game.start_game(assigns.game.id)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, assign(socket, game: game)}
  end

  def handle_event("start_turn", %{}, %{assigns: assigns} = socket) do
    game = Timesup.Game.start_turn(assigns.game.id)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, assign(socket, game: game)}
  end

  def handle_event("card_guessed", %{}, %{assigns: assigns} = socket) do
    game = Timesup.Game.card_guessed(assigns.game.id)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, assign(socket, game: game)}
  end

  def handle_event("pass_card", %{}, %{assigns: assigns} = socket) do
    game = Timesup.Game.pass_card(assigns.game.id)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, assign(socket, game: game)}
  end

  defp choose_team(team, %{assigns: assigns} = socket) do
    game = Timesup.Game.choose_team(assigns.game.id, assigns.current_user, team)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, assign(socket, game: game)}
  end

  def handle_info(%{event: "update", payload: %{game: game}}, socket) do
    {:noreply, assign(socket, game: game)}
  end
end
