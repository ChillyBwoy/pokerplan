defmodule Pokerplan.Repo do
  use Ecto.Repo,
    otp_app: :pokerplan,
    adapter: Ecto.Adapters.SQLite3
end
