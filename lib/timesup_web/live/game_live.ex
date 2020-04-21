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
          DynamicSupervisor.start_child(
            Timesup.GameSupervisor,
            {Timesup.Game, name: {:via, Registry, {Timesup.GameRegistry, game_id}}}
          )

          Timesup.Game.get_game(game_id)
      end

    socket =
      socket
      |> assign(current_user: user)
      |> assign(blink: "")
      |> assign(game: game)

    {:ok, socket}
  end

  def render(%{game: game} = assigns) do
    if game == nil do
      Phoenix.View.render(TimesupWeb.PageView, "404.html", assigns)
    else
      case assigns.game.status do
        :deck_building ->
          Phoenix.View.render(TimesupWeb.PageView, "deck_building.html", assigns)

        :choosing_teams ->
          Phoenix.View.render(TimesupWeb.PageView, "choose_teams.html", assigns)

        :game_started ->
          if game.show_round_intro and game.round != nil do
            Phoenix.View.render(TimesupWeb.PageView, "intro_#{game.round}.html", assigns)
          else
            Phoenix.View.render(TimesupWeb.PageView, "game_started.html", assigns)
          end
      end
    end
  end

  def handle_event("add_card", %{"card" => %{"name" => name}}, %{assigns: assigns} = socket) do
    game = Timesup.Game.add_card(assigns.game.id, name, assigns.current_user)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, assign(socket, game: game)}
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
    choose_team(0, socket)
  end

  def handle_event("choose_team_2", %{}, socket) do
    choose_team(1, socket)
  end

  defp choose_team(team, %{assigns: assigns} = socket) do
    game = Timesup.Game.choose_team(assigns.game.id, assigns.current_user, team)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, assign(socket, game: game)}
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
    TimesupWeb.Endpoint.broadcast(game.id, "blink", %{type: "card_guessed"})
    {:noreply, assign(socket, game: game)}
  end

  def handle_event("pass_card", %{}, %{assigns: assigns} = socket) do
    game = Timesup.Game.pass_card(assigns.game.id)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    TimesupWeb.Endpoint.broadcast(game.id, "blink", %{type: "card_passed"})

    {:noreply, assign(socket, game: game)}
  end

  def handle_event("start_round", _, %{assigns: assigns} = socket) do
    game = Timesup.Game.start_round(assigns.game.id)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, assign(socket, game: game)}
  end

  def handle_info(%{event: "update", payload: %{game: game}}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  def handle_info(%{event: "blink", payload: %{type: type}}, socket) do
    {:noreply, assign(socket, blink: type)}
  end

  def handle_event("blink_received", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, blink: "")}
  end
end
