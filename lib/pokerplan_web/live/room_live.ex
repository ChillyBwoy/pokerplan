defmodule PokerplanWeb.RoomLive do
  use PokerplanWeb, :live_view
  alias Phoenix.PubSub

  alias Pokerplan.RoomState
  alias Pokerplan.Auth.User
  alias PokerplanWeb.Presence

  @topic RoomState.topic()

  @impl true
  def mount(_params, _session, socket) do
    PubSub.subscribe(Pokerplan.PubSub, @topic)
    {:ok, socket |> assign(:counter, RoomState.current())}
  end

  @impl true
  def handle_params(
        %{"room_id" => room_id},
        _uri,
        socket = %{assigns: %{current_user: %User{} = user}}
      ) do
    if connected?(socket) do
      Presence.track_user(%{room_id: room_id}, user)
      Phoenix.PubSub.subscribe(Pokerplan.PubSub, "presence:room:#{room_id}")
    end

    {:noreply,
     socket
     |> assign(:room_id, room_id)
     |> assign(:users, Presence.user_list(%{room_id: room_id}))}
  end

  @impl true
  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        socket = %{assigns: %{users: users}}
      ) do
    {:noreply, socket |> assign(:users, users |> Presence.map_presence(joins, leaves))}
  end

  @impl true
  def handle_info({:count, count}, socket) do
    {:noreply, assign(socket, counter: count)}
  end

  @impl true
  def handle_event("inc", _, socket) do
    {:noreply, assign(socket, :counter, RoomState.incr())}
  end

  @impl true
  def handle_event("dec", _, socket) do
    {:noreply, assign(socket, :counter, RoomState.decr())}
  end

  @impl true
  def terminate(_reason, socket = %{assigns: %{current_user: user = %User{}, room_id: room_id}}) do
    if connected?(socket), do: Presence.untrack_user(%{room_id: room_id}, user.username)
  end
end
