defmodule PokerplanWeb.GameLive do
  use PokerplanWeb, :live_view

  alias Pokerplan.Game.Server, as: GameServer
  alias Pokerplan.Game.State, as: GameState
  alias Pokerplan.Game.VoteChoice, as: VoteChoice
  alias Pokerplan.Auth.User

  alias PokerplanWeb.Presence

  @choices VoteChoice.list({:fibonacci})

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:choices, @choices)}
  end

  @impl true
  def handle_params(
        %{"game_id" => game_id},
        _uri,
        socket = %{assigns: %{current_user: %User{} = current_user}}
      ) do
    if GameServer.active?(game_id) do
      if connected?(socket) do
        {:ok, _} = Presence.track_user({:game, game_id}, current_user)
        :ok = Presence.subscribe({:game, game_id})
        :ok = GameServer.subscribe({:list})
        :ok = GameServer.subscribe({:game, game_id})
      end

      {:noreply,
       socket
       |> assign(:users, Presence.get_users_in_game(game_id))
       |> assign(:game_state, GameServer.current(game_id))}
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
  def handle_info(
        {:game_end, %GameState{} = end_game_state},
        socket = %{assigns: %{game_state: %GameState{} = game_state}}
      ) do
    if end_game_state.id == game_state.id do
      {:noreply,
       socket
       |> put_flash(:info, "Room has been closed")
       |> redirect(to: ~p"/")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "vote",
        %{"value" => value},
        socket = %{
          assigns: %{current_user: %User{} = current_user, game_state: %GameState{} = game_state}
        }
      ) do
    next_game_state =
      GameServer.dispatch(
        {:vote, id: game_state.id, username: current_user.username, value: value}
      )

    {:noreply, socket |> assign(:game_state, next_game_state)}
  end

  def handle_event(
        "reset",
        _params,
        socket = %{assigns: %{game_state: %GameState{} = game_state}}
      ) do
    next_game_state = GameServer.dispatch({:reset, id: game_state.id})
    {:noreply, socket |> assign(:game_state, next_game_state)}
  end

  def handle_event(
        "reveal",
        _params,
        socket = %{assigns: %{game_state: %GameState{} = game_state}}
      ) do
    next_game_state = GameServer.dispatch({:reveal, id: game_state.id})
    {:noreply, socket |> assign(:game_state, next_game_state)}
  end

  @impl true
  def terminate(
        _reason,
        socket = %{
          assigns: %{current_user: %User{} = current_user, game_state: %GameState{} = game_state}
        }
      ) do
    if connected?(socket) do
      Presence.untrack_user({:game, game_state.id}, current_user.username)
    end

    if GameServer.active?(game_state.id) do
      GameServer.dispatch({:player_leave, id: game_state.id, username: current_user.username})
    end

    Presence.unsubscribe({:game, game_state.id})
  end
end
