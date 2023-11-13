defmodule Pokerplan.RoomState do
  use GenServer
  alias Phoenix.PubSub
  @name :count_server

  @start_value 0

  # External API (runs in client process)

  def topic do
    "count"
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, @start_value, name: @name)
  end

  def incr() do
    GenServer.call(@name, :incr)
  end

  def decr() do
    GenServer.call(@name, :decr)
  end

  def current() do
    GenServer.call(@name, :current)
  end

  def init(initial_state) do
    {:ok, initial_state}
  end

  # Implementation (Runs in GenServer process)

  def handle_call(:current, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:incr, _from, state) do
    make_change(state, +1)
  end

  def handle_call(:decr, _from, state) do
    make_change(state, -1)
  end

  defp make_change(state, change) do
    new_state = state + change
    PubSub.broadcast(Pokerplan.PubSub, topic(), {:count, new_state})
    {:reply, new_state, new_state}
  end
end
