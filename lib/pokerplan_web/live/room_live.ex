defmodule PokerplanWeb.RoomLive do
  use PokerplanWeb, :live_view
  alias Phoenix.PubSub

  alias Pokerplan.RoomState
  alias Pokerplan.Auth.User
  alias PokerplanWeb.Presence

  @sequence [1, 2, 3, 5, 8, 13, 21, 34, "?", "☕️"]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:sequence, @sequence)}
  end

  @impl true
  def handle_params(
        %{"room_id" => room_id},
        _uri,
        socket = %{assigns: %{current_user: %User{} = user}}
      ) do
    if connected?(socket) do
      Presence.track_user(%{room_id: room_id}, user)
      PubSub.subscribe(Pokerplan.PubSub, Presence.get_topic(%{room_id: room_id}))
      PubSub.subscribe(Pokerplan.PubSub, RoomState.get_topic(room_id))
    end

    room_state = RoomState.current(room_id)

    {:noreply,
     socket
     |> assign(:users, Presence.user_list(%{room_id: room_id}))
     |> assign(:room_state, room_state)}
  end

  @impl true
  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        socket = %{assigns: %{users: users, room_state: %{room_id: room_id}}}
      ) do
    next_users = users |> Presence.map_presence(joins, leaves)

    if map_size(next_users) == 0 do
      RoomState.stop(room_id)
    end

    {:noreply, assign(socket, :users, next_users)}
  end

  @impl true
  def handle_info({:room_state, room_state}, socket) do
    {:noreply, assign(socket, room_state: room_state)}
  end

  @impl true
  def handle_event(
        "vote",
        %{"value" => value},
        socket = %{
          assigns: %{
            current_user: %{username: username},
            room_state: %{room_id: room_id}
          }
        }
      ) do
    {:noreply, assign(socket, :room_state, RoomState.user_vote(room_id, username, value))}
  end

  # @impl true
  # def handle_event("inc", _, socket = %{assigns: %{room_state: %{room_id: room_id}}}) do
  #   {:noreply, assign(socket, :room_state, RoomState.incr(room_id))}
  # end

  # @impl true
  # def handle_event("dec", _, socket = %{assigns: %{room_state: %{room_id: room_id}}}) do
  #   {:noreply, assign(socket, :counter, RoomState.decr(room_id))}
  # end

  @impl true
  def terminate(
        _reason,
        socket = %{
          assigns: %{
            current_user: user = %User{},
            room_state: %{room_id: room_id, title: _title, users: _users}
          }
        }
      ) do
    if connected?(socket), do: Presence.untrack_user(%{room_id: room_id}, user.username)

    PubSub.unsubscribe(Pokerplan.PubSub, Presence.get_topic(%{room_id: room_id}))
  end
end
