defmodule TimesupWeb.PageController do
  use TimesupWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
