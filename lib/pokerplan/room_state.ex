defmodule Pokerplan.RoomState do
  use GenServer
  alias Phoenix.PubSub

  defp notify(state = %{room_id: room_id}) do
    PubSub.broadcast(Pokerplan.PubSub, get_topic(room_id), {:room_state, state})
    {:reply, state, state}
  end

  defp inital_state(%{room_id: room_id, title: title}) do
    %{room_id: room_id, title: title, users: %{}}
  end

  def get_topic(room_id), do: "pubsub_poker_room_#{room_id}"

  def get_name(room_id), do: String.to_atom("poker_room_#{room_id}")

  def start(params = %{room_id: room_id, title: _title}) do
    name = get_name(room_id)

    GenServer.start(__MODULE__, params, name: name)
  end

  def stop(room_id) do
    GenServer.stop(get_name(room_id))
  end

  def current(room_id) do
    GenServer.call(get_name(room_id), {:current})
  end

  def reset(room_id) do
    GenServer.call(get_name(room_id), {:reset})
  end

  def user_vote(room_id, user_id, value) do
    GenServer.call(get_name(room_id), {:user_vote, user_id, value})
  end

  def init(params = %{room_id: _room_id, title: _title}) do
    {:ok, inital_state(params)}
  end

  # Implementation

  def handle_call({:current}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:user_vote, user_id, value}, _from, state) do
    voted = get_in(state, [:users, user_id])

    if voted == value do
      next_state = put_in(state, [:users, user_id], nil)
      notify(next_state)
    else
      next_state = put_in(state, [:users, user_id], value)
      notify(next_state)
    end
  end

  def handle_call({:reset}, _from, state) do
    next_state =
      state
      |> put_in([:data, :users], %{})

    notify(next_state)
  end
end
