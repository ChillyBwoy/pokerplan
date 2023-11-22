defmodule Pokerplan.Game.Server do
  use GenServer, restart: :transient

  alias Phoenix.PubSub
  alias Pokerplan.Game.State

  def start_link(%State{} = initial_state) do
    GenServer.start_link(__MODULE__, initial_state, name: get_name(initial_state.id))
  end

  @impl true
  def init(%State{} = initial_state) do
    {:ok, initial_state}
  end

  def stop(id) do
    get_name(id) |> GenServer.stop()
  end

  # Public API

  def get_topic(id), do: "pubsub_poker_game_#{id}"

  def active?(id) do
    case GenServer.whereis(get_name(id)) do
      nil -> false
      _ -> true
    end
  end

  def current(id) do
    get_name(id) |> GenServer.call({:current})
  end

  def dispatch({:vote, id: id, username: username, value: value}) do
    get_name(id) |> GenServer.call({:vote, username, value})
  end

  def dispatch({:reveal, id: id}) do
    get_name(id) |> GenServer.call({:reveal})
  end

  def dispatch({:reset, id: id}) do
    get_name(id) |> GenServer.call({:reset})
  end

  # Callbacks

  @impl true
  def handle_call({:current}, _from, state) do
    reply(state)
  end

  @impl true
  def handle_call({:vote, username, value}, _from, %State{} = state) do
    State.vote(state, username, value) |> reply({:notify})
  end

  @impl true
  def handle_call({:reveal}, _from, %State{} = state) do
    State.show(state) |> reply({:notify})
  end

  @impl true
  def handle_call({:reset}, _from, %State{} = state) do
    State.reset(state) |> reply({:notify})
  end

  # Private funcs

  defp reply(%State{} = state) do
    {:reply, state, state}
  end

  defp reply(%State{} = state, {:notify}) do
    PubSub.broadcast(Pokerplan.PubSub, get_topic(state.id), {:game_state, state})
    {:reply, state, state}
  end

  defp get_name(id), do: {:via, Registry, {Pokerplan.Registry, "poker_game_#{id}"}}
end
