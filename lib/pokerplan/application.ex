defmodule Pokerplan.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      PokerplanWeb.Telemetry,
      Pokerplan.Game.Supervisor,
      {Registry, keys: :unique, name: Pokerplan.Registry},
      # Start the PubSub system
      {Phoenix.PubSub, name: Pokerplan.PubSub},
      PokerplanWeb.Presence,
      # Start the Endpoint (http/https)
      PokerplanWeb.Endpoint
      # Start a worker by calling: Pokerplan.Worker.start_link(arg)
      # {Pokerplan.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pokerplan.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PokerplanWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
