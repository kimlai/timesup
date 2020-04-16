defmodule TimesupWeb.Router do
  use TimesupWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {TimesupWeb.LayoutView, :root}
  end

  scope "/", TimesupWeb do
    pipe_through :browser

    get "/", PageController, :index
    post "/create-game", PageController, :create_game
    get "/game/:id/join", PageController, :choose_username
    post "/game/:id/join", PageController, :join_game

    live "/game/:id", GameLive
  end
end
