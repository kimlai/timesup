defmodule TimesupWeb.Presence do
  use Phoenix.Presence,
    otp_app: :timesup,
    pubsub_server: Timesup.PubSub
end
