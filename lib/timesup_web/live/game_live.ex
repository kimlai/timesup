defmodule TimesupWeb.GameLive do
  use Phoenix.LiveView, layout: {TimesupWeb.LayoutView, "live.html"}
  alias Timesup.GameServer
  alias TimesupWeb.Presence

  def mount(%{"id" => game_id}, %{"current_user" => user}, socket) do
    if connected?(socket), do: TimesupWeb.Endpoint.subscribe(game_id)

    game =
      try do
        Timesup.GameServer.get_game(game_id)
      catch
        # most likely a new deployment destroyed the process
        :exit, _ ->
          DynamicSupervisor.start_child(
            Timesup.GameSupervisor,
            {GameServer, name: {:via, Registry, {Timesup.GameRegistry, game_id}}}
          )

          Timesup.GameServer.get_game(game_id)
      end

    Presence.track(
      self(),
      game_id,
      user,
      %{name: user}
    )

    socket =
      socket
      |> assign(current_user: user)
      |> assign(blink: "")
      |> assign(game: game)
      |> assign(connect_users: fetch_connected_users(game_id))

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
    game = Timesup.GameServer.add_card(assigns.game.id, name, assigns.current_user)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, assign(socket, game: game)}
  end

  def handle_event("toggle_player_ready", _, %{assigns: assigns} = socket) do
    game = Timesup.GameServer.toggle_player_ready(assigns.game.id, assigns.current_user)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, assign(socket, game: game)}
  end

  def handle_event("start_choosing_teams", _, %{assigns: assigns} = socket) do
    game = Timesup.GameServer.start_choosing_teams(assigns.game.id)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, assign(socket, game: game)}
  end

  def handle_event("choose_team", %{"team" => team}, %{assigns: assigns} = socket) do
    game =
      Timesup.GameServer.choose_team(
        assigns.game.id,
        assigns.current_user,
        String.to_integer(team)
      )

    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, assign(socket, game: game)}
  end

  def handle_event("start_game", _, %{assigns: assigns} = socket) do
    game = Timesup.GameServer.start_game(assigns.game.id)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, assign(socket, game: game)}
  end

  def handle_event("start_turn", _, %{assigns: assigns} = socket) do
    game = Timesup.GameServer.start_turn(assigns.game.id)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, assign(socket, game: game)}
  end

  def handle_event("card_guessed", %{"card" => card}, %{assigns: assigns} = socket) do
    case Timesup.GameServer.card_guessed(assigns.game.id, card) do
      {:ok, game} ->
        TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
        TimesupWeb.Endpoint.broadcast(game.id, "blink", %{type: "card_guessed"})
        {:noreply, assign(socket, game: game)}

      :error ->
        {:noreply, socket}
    end
  end

  def handle_event("pass_card", %{"card" => card}, %{assigns: assigns} = socket) do
    case Timesup.GameServer.pass_card(assigns.game.id, card) do
      {:ok, game} ->
        TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
        TimesupWeb.Endpoint.broadcast(game.id, "blink", %{type: "card_passed"})
        {:noreply, assign(socket, game: game)}

      :error ->
        {:noreply, socket}
    end
  end

  def handle_event("start_round", _, %{assigns: assigns} = socket) do
    game = Timesup.GameServer.start_round(assigns.game.id)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, assign(socket, game: game)}
  end

  def handle_event("blink_received", _, socket) do
    {:noreply, assign(socket, blink: "")}
  end

  def handle_event("skip_player", %{"player" => player}, %{assigns: assigns} = socket) do
    game = Timesup.GameServer.skip_player(assigns.game.id, player)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})

    {:noreply, assign(socket, game: game)}
  end

  def handle_event("delete_card", %{"index" => index}, %{assigns: assigns} = socket) do
    game =
      Timesup.GameServer.delete_card(
        assigns.game.id,
        assigns.current_user,
        String.to_integer(index)
      )

    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})

    {:noreply, assign(socket, game: game)}
  end

  def handle_info(%{event: "update", payload: %{game: game}}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  def handle_info(%{event: "blink", payload: %{type: type}}, socket) do
    {:noreply, assign(socket, blink: type)}
  end

  def handle_info(%{event: "presence_diff"}, %{assigns: %{game: game}} = socket) do
    {:noreply, assign(socket, connect_users: fetch_connected_users(game.id))}
  end

  defp fetch_connected_users(game_id) do
    game_id
    |> Presence.list()
    |> Enum.map(fn {_, data} -> List.first(data[:metas]) end)
    |> Enum.map(fn user -> user.name end)
  end
end
