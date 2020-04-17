defmodule TimesupWeb.PageController do
  use TimesupWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def create_game(conn, _params) do
    game_id = random_id()

    DynamicSupervisor.start_child(
      Timesup.GameSupervisor,
      {Timesup.Game, name: {:via, Registry, {Timesup.GameRegistry, game_id}}}
    )

    redirect(conn, to: "/game/#{game_id}/join")
  end

  def choose_username(conn, %{"id" => id}) do
    render(conn, "join_game.html", id: id)
  end

  def join_game(conn, %{"id" => game_id, "username" => username}) do
    Timesup.Game.join(game_id, username)
    Phoenix.PubSub.broadcast!(Timesup.PubSub, game_id, :update)

    conn
    |> put_session(:current_user, username)
    |> redirect(to: "/game/#{game_id}")
  end

  # stolen from https://elixirforum.com/t/generating-alphanumeric-strings-for-permalinks/11540/5
  defp random_id() do
    10
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end
end
