defmodule Pokerplan.Game.Server do
  use GenServer
  alias Phoenix.PubSub
  alias Pokerplan.Game.State
  alias Pokerplan.Auth.User

  defp reply(%State{} = state) do
    {:reply, state, state}
  end

  defp reply(%State{} = state, {:notify}) do
    PubSub.broadcast(Pokerplan.PubSub, get_topic(state.id), {:game_state, state})
    {:reply, state, state}
  end

  defp get_name(id), do: String.to_atom("poker_game_#{id}")

  def get_topic(id), do: "pubsub_poker_game_#{id}"

  def create_new_game(%{title: title, owner: %User{} = owner}) do
    initial_state = State.new(%{title: title, owner: owner})

    case GenServer.start(__MODULE__, initial_state, name: get_name(initial_state.id)) do
      {:ok, pid} ->
        {:ok, initial_state.id, pid}

      _ ->
        {:error, "Could not start game server"}
    end
  end

  def init(%State{} = initial_state) do
    {:ok, initial_state}
  end

  def stop(id) do
    GenServer.stop(get_name(id))
  end

  def active?(id) do
    case GenServer.whereis(get_name(id)) do
      nil -> false
      _ -> true
    end
  end

  def current(id) do
    GenServer.call(get_name(id), {:current})
  end

  def dispatch({:vote, id: id, username: username, value: value}) do
    GenServer.call(get_name(id), {:vote, username, value})
  end

  def dispatch({:reveal, id: id}) do
    GenServer.call(get_name(id), {:reveal})
  end

  def dispatch({:reset, id: id}) do
    GenServer.call(get_name(id), {:reset})
  end

  # Implementation

  def handle_call({:current}, _from, state) do
    reply(state)
  end

  def handle_call({:vote, username, value}, _from, %State{} = state) do
    State.vote(state, username, value) |> reply({:notify})
  end

  def handle_call({:reveal}, _from, %State{} = state) do
    State.show(state) |> reply({:notify})
  end

  def handle_call({:reset}, _from, %State{} = state) do
    State.reset(state) |> reply({:notify})
  end
end
