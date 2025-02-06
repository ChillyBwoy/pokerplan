defmodule Pokerplan.Poker.Supervisor do
  use DynamicSupervisor

  alias Pokerplan.Poker.CardTable
  alias Pokerplan.Poker.GameState
  alias Pokerplan.Auth.User

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def start_new_game(%{title: title, choices: choices, owner: %User{} = owner})
      when is_binary(title) and is_atom(choices) do
    initial_state = GameState.new(%{title: title, choices: choices, owner: owner})

    case DynamicSupervisor.start_child(__MODULE__, {CardTable, initial_state}) do
      {:ok, _pid} ->
        {:ok, initial_state.id}

      {:error, _reason} ->
        {:error, "Could not create a poker table"}
    end
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def list_games() do
    DynamicSupervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} -> :sys.get_state(pid) end)
  end
end
