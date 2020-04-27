defmodule TimesupWeb.PageController do
  use TimesupWeb, :controller
  alias Timesup.Repo
  alias Timesup.Game
  alias Timesup.GameServer
  alias Timesup.StoredGame
  import Ecto.Changeset

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def create_game(conn, _params) do
    game =
      random_id()
      |> Game.new()
      # we write the to database now because the game GenServer will try to
      # fetch the existing state from the DB as soon as it starts up
      |> write_to_database()

    DynamicSupervisor.start_child(
      Timesup.GameSupervisor,
      {GameServer, name: {:via, Registry, {Timesup.GameRegistry, game.id}}}
    )

    redirect(conn, to: "/game/#{game.id}/join")
  end

  defp write_to_database(%Game{} = game) do
    game
    |> StoredGame.from_game()
    |> Repo.insert!()

    game
  end

  def choose_username(conn, %{"id" => id}) do
    render(conn, "join_game.html", id: id, changeset: user_changeset())
  end

  def join_game(conn, %{"id" => game_id, "player" => player}) do
    game = GameServer.get_game(game_id)

    player
    |> user_changeset()
    |> validate_not_too_many_players(game)
    |> apply_action(:validate)
    |> case do
      {:ok, player} ->
        game = GameServer.join(game_id, player.name)
        TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})

        conn
        |> put_session(:current_user, player.name)
        |> redirect(to: Routes.live_path(TimesupWeb.Endpoint, TimesupWeb.GameLive, game_id))

      {:error, changeset} ->
        render(conn, "join_game.html", id: game_id, changeset: changeset)
    end
  end

  def odd_number_of_players(conn, _) do
    render(conn, "odd_number_of_players.html")
  end

  defp user_changeset(attrs \\ %{}) do
    {%{}, %{name: :string}}
    |> cast(attrs, [:name])
    |> update_change(:name, &String.trim/1)
    |> validate_required([:name])
  end

  defp validate_not_too_many_players(changeset, game) do
    # it does not make sense to validate :name, but it puts the error when we want it in the HTML
    validate_change(changeset, :name, fn _, _ ->
      if map_size(game.players) > 99 do
        [name: "Une partie est limitée à 100 joueurs"]
      else
        []
      end
    end)
  end

  # stolen from https://elixirforum.com/t/generating-alphanumeric-strings-for-permalinks/11540/5
  defp random_id() do
    10
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
