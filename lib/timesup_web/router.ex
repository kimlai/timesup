defmodule TimesupWeb.Router do
  use TimesupWeb, :router
  use Plug.ErrorHandler
  use Sentry.Plug
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {TimesupWeb.LayoutView, :root}
  end

  pipeline :admin do
    plug :auth
  end

  scope "/", TimesupWeb do
    pipe_through :browser

    get "/", PageController, :index
    post "/create-game", PageController, :create_game
    get "/game/:id/join", PageController, :choose_username
    post "/game/:id/join", PageController, :join_game
    get "/odd_number_of_players", PageController, :odd_number_of_players

    live "/game/:id", GameLive
  end

  scope "/", TimesupWeb do
    pipe_through [:browser, :admin]
    live_dashboard "/dashboard", metrics: TimesupWeb.Telemetry
  end

  # https://hexdocs.pm/plug/1.10.0/Plug.BasicAuth.html#module-low-level-usage
  defp auth(conn, _opts) do
    with {user, password} <- Plug.BasicAuth.parse_basic_auth(conn),
         true <- check_credentials(user, password) do
      conn
    else
      _ -> conn |> Plug.BasicAuth.request_basic_auth() |> halt()
    end
  end

  defp check_credentials(user, password) do
    Plug.Crypto.secure_compare(user, System.get_env("ADMIN_USER")) &&
      Plug.Crypto.secure_compare(password, System.get_env("ADMIN_PASSWORD"))
  end
end
