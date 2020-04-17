defmodule TimesupWeb.GameLive do
  use Phoenix.LiveView, layout: {TimesupWeb.LayoutView, "live.html"}

  def mount(%{"id" => game_id}, %{"current_user" => user}, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Timesup.PubSub, game_id)

    socket =
      socket
      |> assign(current_user: user)
      |> assign_game(game_id)

    {:ok, socket}
  end

  defp assign_game(socket, game_id) do
    socket
    |> assign(game_id: game_id)
    |> assign_game()
  end

  defp assign_game(%{assigns: %{game_id: game_id}} = socket) do
    assign(socket, game: Timesup.Game.game(game_id))
  end

  def render(assigns) do
    case assigns.game.status do
      :deck_building ->
        Phoenix.View.render(TimesupWeb.PageView, "deck_building.html", assigns)

      :choosing_teams ->
        Phoenix.View.render(TimesupWeb.PageView, "choose_teams.html", assigns)

      :game_started ->
        Phoenix.View.render(TimesupWeb.PageView, "game_started.html", assigns)
    end
  end

  def handle_event("add_card", %{"card" => %{"name" => name}}, %{assigns: assigns} = socket) do
    {:noreply,
     assign(socket, :game, Timesup.Game.add_card(assigns.game_id, name, assigns.current_user))}
  end

  def handle_event("set_player_ready", %{}, %{assigns: assigns} = socket) do
    Timesup.Game.set_player_ready(assigns.game_id, assigns.current_user)
    Phoenix.PubSub.broadcast!(Timesup.PubSub, assigns.game_id, :update)
    {:noreply, assign_game(socket)}
  end

  def handle_event("start_choosing_teams", %{}, %{assigns: assigns} = socket) do
    Timesup.Game.start_choosing_teams(assigns.game_id)
    Phoenix.PubSub.broadcast!(Timesup.PubSub, assigns.game_id, :update)
    {:noreply, assign_game(socket)}
  end

  def handle_event("choose_team_1", %{}, socket) do
    choose_team(:team_1, socket)
  end

  def handle_event("choose_team_2", %{}, socket) do
    choose_team(:team_2, socket)
  end

  def handle_event("start_game", %{}, %{assigns: assigns} = socket) do
    Timesup.Game.start_game(assigns.game_id)
    Phoenix.PubSub.broadcast!(Timesup.PubSub, assigns.game_id, :update)
    {:noreply, assign_game(socket)}
  end

  def handle_event("start_turn", %{}, %{assigns: assigns} = socket) do
    Timesup.Game.start_turn(assigns.game_id)
    Phoenix.PubSub.broadcast!(Timesup.PubSub, assigns.game_id, :update)
    {:noreply, assign_game(socket)}
  end

  def handle_event("card_guessed", %{}, %{assigns: assigns} = socket) do
    Timesup.Game.card_guessed(assigns.game_id)
    Phoenix.PubSub.broadcast!(Timesup.PubSub, assigns.game_id, :update)
    {:noreply, assign_game(socket)}
  end

  def handle_event("pass_card", %{}, %{assigns: assigns} = socket) do
    Timesup.Game.pass_card(assigns.game_id)
    Phoenix.PubSub.broadcast!(Timesup.PubSub, assigns.game_id, :update)
    {:noreply, assign_game(socket)}
  end

  defp choose_team(team, %{assigns: assigns} = socket) do
    Timesup.Game.choose_team(assigns.game_id, assigns.current_user, team)
    Phoenix.PubSub.broadcast!(Timesup.PubSub, assigns.game_id, :update)
    {:noreply, assign_game(socket) |> assign(time_remaining: 30)}
  end

  def handle_info(:update, socket) do
    {:noreply, assign_game(socket)}
  end
end
