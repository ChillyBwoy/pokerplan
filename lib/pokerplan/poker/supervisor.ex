defmodule Pokerplan.Poker.Supervisor do
  use DynamicSupervisor

  require Logger
  alias Pokerplan.Poker.CardTable
  alias Pokerplan.Poker.GameState
  alias Pokerplan.Auth.User

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def start_new_game(%{title: title, choices: choices, creator: %User{} = creator})
      when is_binary(title) and is_binary(choices) do
    with {:ok, initial_state} <-
           GameState.create(%{title: title, choices: choices, creator: creator}),
         {:ok, pid} <- DynamicSupervisor.start_child(__MODULE__, {CardTable, initial_state}) do
      {:ok, pid, initial_state}
    else
      {:error, reason} ->
        Logger.error(reason)
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
