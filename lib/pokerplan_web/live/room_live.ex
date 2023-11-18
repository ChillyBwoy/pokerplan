defmodule PokerplanWeb.RoomLive do
  use PokerplanWeb, :live_view
  alias Phoenix.PubSub

  alias Pokerplan.Auth.User
  alias Pokerplan.RoomState
  alias Pokerplan.VoteChoice
  alias PokerplanWeb.Presence

  @choices [
    %VoteChoice{value: 0, label: "?"},
    %VoteChoice{value: 1, label: "1"},
    %VoteChoice{value: 2, label: "2"},
    %VoteChoice{value: 3, label: "3"},
    %VoteChoice{value: 5, label: "5"},
    %VoteChoice{value: 8, label: "8"},
    %VoteChoice{value: 13, label: "13"},
    %VoteChoice{value: 21, label: "21"},
    %VoteChoice{value: 34, label: "34"},
    %VoteChoice{value: 55, label: "55"},
    %VoteChoice{value: 89, label: "89"},
    %VoteChoice{value: 0, label: "☕️"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:choices, @choices)}
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
        socket = %{assigns: %{users: users}}
      ) do
    next_users = users |> Presence.map_presence(joins, leaves)
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
    {:noreply, assign(socket, :room_state, RoomState.vote(room_id, username, value))}
  end

  def handle_event(
        "reset",
        _unsigned_params,
        socket = %{assigns: %{room_state: %{room_id: room_id}}}
      ) do
    {:noreply, assign(socket, :room_state, RoomState.reset(room_id))}
  end

  def handle_event(
        "reveal",
        _unsigned_params,
        socket = %{assigns: %{room_state: %{room_id: room_id}}}
      ) do
    {:noreply, assign(socket, :room_state, RoomState.reveal(room_id))}
  end

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
