defmodule PokerplanWeb.GameLive do
  use PokerplanWeb, :live_view

  alias Phoenix.PubSub

  alias Pokerplan.Game.Data, as: GameData
  alias Pokerplan.Game.Server, as: GameServer
  alias Pokerplan.Game.State, as: GameState
  alias Pokerplan.Auth.User

  alias PokerplanWeb.Presence

  @choices GameData.choices({:fibonacci})

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:choices, @choices)}
  end

  @impl true
  def handle_params(
        %{"game_id" => id},
        _uri,
        socket = %{assigns: %{current_user: %User{} = current_user}}
      ) do
    if GameServer.active?(id) do
      if connected?(socket) do
        Presence.track_user(%{game_id: id}, current_user)
        PubSub.subscribe(Pokerplan.PubSub, Presence.get_topic(%{game_id: id}))
        PubSub.subscribe(Pokerplan.PubSub, GameServer.get_topic(id))
      end

      {:noreply,
       socket
       |> assign(:users, Presence.user_list(%{game_id: id}))
       |> assign(:game_state, GameServer.current(id))}
    else
      {:noreply, socket |> put_flash(:error, "Room not found") |> redirect(to: ~p"/")}
    end
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
  def handle_info({:game_state, game_state}, socket) do
    {:noreply, assign(socket, game_state: game_state)}
  end

  @impl true
  def handle_event(
        "vote",
        %{"value" => value},
        socket = %{
          assigns: %{
            current_user: %User{} = current_user,
            game_state: %GameState{} = game_state
          }
        }
      ) do
    {:noreply,
     assign(
       socket,
       :game_state,
       GameServer.dispatch(
         {:vote, id: game_state.id, username: current_user.username, value: value}
       )
     )}
  end

  def handle_event(
        "reset",
        _unsigned_params,
        socket = %{assigns: %{game_state: %GameState{} = game_state}}
      ) do
    {:noreply, assign(socket, :game_state, GameServer.dispatch({:reset, id: game_state.id}))}
  end

  def handle_event(
        "reveal",
        _unsigned_params,
        socket = %{assigns: %{game_state: %GameState{} = game_state}}
      ) do
    {:noreply, assign(socket, :game_state, GameServer.dispatch({:reveal, id: game_state.id}))}
  end

  def handle_event(
        "close",
        _unsigned_params,
        socket = %{assigns: %{game_state: %GameState{} = game_state}}
      ) do
    GameServer.stop(game_state.id)
    {:noreply, socket |> put_flash(:info, "Room has been closed") |> redirect(to: ~p"/")}
  end

  @impl true
  def terminate(
        _reason,
        socket = %{
          assigns: %{
            current_user: %User{} = user,
            game_state: %GameState{} = game_state
          }
        }
      ) do
    if connected?(socket),
      do: Presence.untrack_user(%{game_id: game_state.id}, user.username)

    PubSub.unsubscribe(Pokerplan.PubSub, Presence.get_topic(%{game_id: game_state.id}))
  end
end
