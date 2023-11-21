defmodule Pokerplan.Game.Supervisor do
  use DynamicSupervisor

  alias Pokerplan.Game.State
  alias Pokerplan.Auth.User

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def start_new_game(%{title: title, owner: %User{} = owner}) do
    initial_state = State.new(%{title: title, owner: owner})

    case DynamicSupervisor.start_child(__MODULE__, {Pokerplan.Game.Server, initial_state}) do
      {:ok, _pid} ->
        {:ok, initial_state.id}

      {:error, _reason} ->
        {:error, "Could not start game server"}
    end
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
