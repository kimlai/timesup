defmodule TimesupWeb.PageController do
  use TimesupWeb, :controller
  alias Timesup.Repo
  alias Timesup.GameState
  alias Timesup.StoredGame

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def create_game(conn, _params) do
    game =
      random_id()
      |> GameState.new()
      # we write the to database now because the game GenServer will try to
      # fetch the existing state from the DB as soon as it starts up
      |> write_to_database()

    DynamicSupervisor.start_child(
      Timesup.GameSupervisor,
      {Timesup.Game, name: {:via, Registry, {Timesup.GameRegistry, game.id}}}
    )

    redirect(conn, to: "/game/#{game.id}/join")
  end

  defp write_to_database(%GameState{} = game) do
    game
    |> StoredGame.from_game_state()
    |> Repo.insert!()

    game
  end

  def choose_username(conn, %{"id" => id}) do
    render(conn, "join_game.html", id: id)
  end

  def join_game(conn, %{"id" => game_id, "username" => username}) do
    game = Timesup.Game.join(game_id, username)
    TimesupWeb.Endpoint.broadcast(game.id, "update", %{game: game})

    conn
    |> put_session(:current_user, username)
    |> redirect(to: Routes.live_path(TimesupWeb.Endpoint, TimesupWeb.GameLive, game_id))
  end

  # stolen from https://elixirforum.com/t/generating-alphanumeric-strings-for-permalinks/11540/5
  defp random_id() do
    10
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
