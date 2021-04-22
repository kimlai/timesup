defmodule Timesup.GameExpiredError do
  defexception message: "Game expired", plug_status: :not_found
end
