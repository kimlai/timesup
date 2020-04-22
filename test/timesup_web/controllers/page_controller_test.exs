defmodule TimesupWeb.PageControllerTest do
  use TimesupWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Time's Up"
  end
end
