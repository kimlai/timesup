defmodule TimesupWeb.GameChannel do
  use Phoenix.Channel

  def join("game:" <> game_id, socket) do
    {:ok, socket}
  end
end
