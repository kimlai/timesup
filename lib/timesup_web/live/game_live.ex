defmodule TimesupWeb.GameLive do
  use Phoenix.LiveView, layout: {TimesupWeb.LayoutView, "live.html"}
  alias Timesup.GameServer
  alias TimesupWeb.Presence
  alias TimesupWeb.Router.Helpers, as: Routes
  import Ecto.Changeset

  def mount(%{"id" => game_id}, %{"current_user" => user}, socket) do
    if connected?(socket), do: TimesupWeb.Endpoint.subscribe(game_id)

    if Registry.lookup(Timesup.GameRegistry, game_id) == [] do
      raise Timesup.GameNotFoundError
    end

    game = GameServer.get_game(game_id)

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
      |> assign(card_changeset: card_changeset())
      |> assign(connect_users: fetch_connected_users(game_id))

    {:ok, socket, temporary_assigns: [clear_input: false]}
  end

  def mount(%{"id" => game_id}, _, socket) do
    {:ok, redirect(socket, to: Routes.page_path(TimesupWeb.Endpoint, :join_game, game_id))}
  end

  def render(%{game: game} = assigns) do
    case assigns.game.status do
      :deck_building ->
        Phoenix.View.render(TimesupWeb.PageView, "deck_building.html", assigns)

      :choosing_teams ->
        Phoenix.View.render(TimesupWeb.PageView, "choose_teams.html", assigns)

      :game_started ->
        cond do
          Timesup.Game.game_over?(game) ->
            Phoenix.View.render(TimesupWeb.PageView, "game_ended.html", assigns)

          game.show_round_intro ->
            Phoenix.View.render(TimesupWeb.PageView, "intro_#{game.round}.html", assigns)

          true ->
            Phoenix.View.render(TimesupWeb.PageView, "game_started.html", assigns)
        end
    end
  end

  def handle_event("validate_card", %{"card" => params}, socket) do
    changeset =
      params
      |> card_changeset()
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, card_changeset: changeset)}
  end

  def handle_event("add_card", %{"card" => params}, %{assigns: assigns} = socket) do
    params
    |> card_changeset()
    |> apply_action(:validate)
    |> case do
      {:ok, card} ->
        game = Timesup.GameServer.add_card(assigns.game.id, card.name, assigns.current_user)
        TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
        {:noreply, assign(socket, card_changeset: card_changeset())}

      {:error, changeset} ->
        {:noreply, assign(socket, card_changeset: changeset)}
    end
  end

  def handle_event("toggle_player_ready", _, %{assigns: assigns} = socket) do
    game = Timesup.GameServer.toggle_player_ready(assigns.game.id, assigns.current_user)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, socket}
  end

  def handle_event("start_choosing_teams", _, %{assigns: assigns} = socket) do
    game = Timesup.GameServer.start_choosing_teams(assigns.game.id)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, socket}
  end

  def handle_event("choose_team", %{"team" => team}, %{assigns: assigns} = socket) do
    game =
      Timesup.GameServer.choose_team(
        assigns.game.id,
        assigns.current_user,
        String.to_integer(team)
      )

    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, socket}
  end

  def handle_event("start_game", _, %{assigns: assigns} = socket) do
    game = Timesup.GameServer.start_game(assigns.game.id)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, socket}
  end

  def handle_event("start_turn", _, %{assigns: assigns} = socket) do
    game = Timesup.GameServer.start_turn(assigns.game.id)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, socket}
  end

  def handle_event("card_guessed", %{"deck_length" => deck_length}, %{assigns: assigns} = socket) do
    case Timesup.GameServer.card_guessed(
           assigns.game.id,
           String.to_integer(deck_length),
           assigns.current_user
         ) do
      {:ok, game} ->
        TimesupWeb.Endpoint.broadcast(game.id, "card_guessed", %{game: game})
        {:noreply, socket}

      :error ->
        {:noreply, socket}
    end
  end

  def handle_event("pass_card", %{"card" => card}, %{assigns: assigns} = socket) do
    case Timesup.GameServer.pass_card(assigns.game.id, card) do
      {:ok, game} ->
        TimesupWeb.Endpoint.broadcast(game.id, "card_passed", %{game: game})
        {:noreply, socket}

      :error ->
        {:noreply, socket}
    end
  end

  def handle_event("start_round", _, %{assigns: assigns} = socket) do
    game = Timesup.GameServer.start_round(assigns.game.id)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, socket}
  end

  def handle_event("blink_received", _, socket) do
    {:noreply, assign(socket, blink: "")}
  end

  def handle_event("skip_player", %{"player" => player}, %{assigns: assigns} = socket) do
    game = Timesup.GameServer.skip_player(assigns.game.id, player)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})
    {:noreply, socket}
  end

  def handle_event("delete_card", %{"index" => index}, %{assigns: assigns} = socket) do
    game =
      Timesup.GameServer.delete_card(
        assigns.game.id,
        assigns.current_user,
        String.to_integer(index)
      )

    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})

    {:noreply, socket}
  end

  def handle_info(%{event: "update", payload: %{game: game}}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  def handle_info(%{event: "card_guessed", payload: %{game: game}}, socket) do
    {:noreply, assign(socket, blink: "card_guessed", game: game)}
  end

  def handle_info(%{event: "card_passed", payload: %{game: game}}, socket) do
    {:noreply, assign(socket, blink: "card_passed", game: game)}
  end

  def handle_info(%{event: "presence_diff"}, %{assigns: %{game: nil}} = socket) do
    {:noreply, socket}
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

  defp card_changeset(attrs \\ %{}) do
    {%{}, %{name: :string}}
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
