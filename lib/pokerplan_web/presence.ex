defmodule PokerplanWeb.Presence do
  use Phoenix.Presence,
    otp_app: :app,
    pubsub_server: Pokerplan.PubSub
end
