defmodule Timesup.GameNotFoundError do
  defexception message: "Game not found", plug_status: :not_found
end
