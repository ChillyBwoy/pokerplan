defmodule Pokerplan.RoomState do
  use GenServer
  alias Phoenix.PubSub

  # External API (runs in client process)

  def get_topic(room_id), do: "pubsub_poker_room_#{room_id}"

  def get_name(room_id), do: String.to_atom("poker_room_#{room_id}")

  defp notify(state = %{room_id: room_id, data: _data}) do
    PubSub.broadcast(Pokerplan.PubSub, get_topic(room_id), {:room_state, state})
    {:reply, state, state}
  end

  # def start_link(_opts) do
  #   GenServer.start_link(__MODULE__, @start_value, name: @name)
  # end

  def start(initial_state = %{room_id: room_id, data: _data}) do
    name = get_name(room_id)

    GenServer.start(__MODULE__, initial_state, name: name)
  end

  def stop(room_id) do
    GenServer.stop(get_name(room_id))
  end

  def incr(room_id) do
    GenServer.call(get_name(room_id), :incr)
  end

  def decr(room_id) do
    GenServer.call(get_name(room_id), :decr)
  end

  def current(room_id) do
    name = get_name(room_id)
    GenServer.call(name, :current)
  end

  def init(
        initial_state = %{
          room_id: _room_id,
          data: %{title: _title, count: _count}
        }
      ) do
    {:ok, initial_state}
  end

  # Implementation (Runs in GenServer process)

  def handle_call(:current, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:incr, _from, state) do
    count = get_in(state, [:data, :count])
    next_state = put_in(state, [:data, :count], count + 1)
    notify(next_state)
  end

  def handle_call(:decr, _from, state) do
    count = get_in(state, [:data, :count])
    next_state = put_in(state, [:data, :count], count - 1)
    notify(next_state)
  end
end
