defmodule Pokerplan.RoomState do
  use GenServer
  alias Phoenix.PubSub

  defp notify(state = %{room_id: room_id}) do
    PubSub.broadcast(Pokerplan.PubSub, get_topic(room_id), {:room_state, state})
    {:reply, state, state}
  end

  defp inital_state(%{room_id: room_id, title: title}) do
    %{room_id: room_id, title: title, show_results: false, users: %{}}
  end

  defp get_name(room_id), do: String.to_atom("poker_room_#{room_id}")

  def get_topic(room_id), do: "pubsub_poker_room_#{room_id}"

  def create_new_room(%{title: title}) do
    room_id = UUID.uuid4(:hex)

    case GenServer.start(__MODULE__, %{title: title, room_id: room_id}, name: get_name(room_id)) do
      {:ok, _pid} ->
        {:ok, room_id}

      _ ->
        {:error, "Could not start room"}
    end
  end

  def stop(room_id) do
    GenServer.stop(get_name(room_id))
  end

  def current(room_id) do
    GenServer.call(get_name(room_id), {:current})
  end

  def vote(room_id, user_id, value) do
    GenServer.call(get_name(room_id), {:vote, user_id, value})
  end

  def reveal(room_id) do
    GenServer.call(get_name(room_id), {:reveal})
  end

  def reset(room_id) do
    GenServer.call(get_name(room_id), {:reset})
  end

  def init(params = %{room_id: _room_id, title: _title}) do
    {:ok, inital_state(params)}
  end

  # Implementation

  def handle_call({:current}, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:vote, user_id, value}, _from, state) do
    voted = get_in(state, [:users, user_id])

    state |> put_in([:users, user_id], if(voted == value, do: nil, else: value)) |> notify()
  end

  def handle_call({:reveal}, _from, state) do
    state |> put_in([:show_results], true) |> notify()
  end

  def handle_call({:reset}, _from, state) do
    inital_state(state) |> notify()
  end
end
