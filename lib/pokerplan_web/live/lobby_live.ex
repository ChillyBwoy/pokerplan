defmodule PokerplanWeb.LobbyLive do
  use PokerplanWeb, :live_view

  alias Pokerplan.Auth.User
  alias Pokerplan.Game.Server, as: GameServer
  alias Pokerplan.Game.State, as: GameState
  alias Pokerplan.Game.Supervisor, as: GameSupervisor
  alias Pokerplan.Game.NewGameForm
  alias PokerplanWeb.Presence

  def mount(_params, _session, socket = %{assigns: %{current_user: %User{} = current_user}}) do
    {:ok, _} = Presence.track_user({:lobby}, current_user)
    :ok = Presence.subscribe({:lobby})
    :ok = GameServer.subscribe({:list})

    form =
      %NewGameForm{}
      |> NewGameForm.changeset(%{})
      |> to_form(as: :game_form)

    {:ok,
     socket
     |> assign(:users, Presence.get_users_in_lobby())
     |> assign(:games, GameSupervisor.list_games())
     |> assign(:form, form)}
  end

  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        socket = %{assigns: %{users: users}}
      ) do
    next_users = users |> Presence.map_presence(joins, leaves)
    {:noreply, assign(socket, :users, next_users)}
  end

  def handle_info({:game_start, %GameState{}}, socket) do
    {:noreply, assign(socket, :games, GameSupervisor.list_games())}
  end

  def handle_info({:game_end, %GameState{}}, socket) do
    {:noreply, assign(socket, :games, GameSupervisor.list_games())}
  end

  def handle_event("validate", %{"game_form" => params}, socket) do
    form =
      %NewGameForm{}
      |> NewGameForm.changeset(params)
      |> Map.put(:action, :validate)
      |> to_form(as: :game_form)

    {:noreply, assign(socket, form: form)}
  end

  def handle_event(
        "save",
        %{"game_form" => %{"title" => title}},
        socket = %{assigns: %{current_user: %User{} = current_user}}
      ) do
    case GameSupervisor.start_new_game(%{title: title, owner: current_user}) do
      {:ok, room_id} ->
        {:noreply, socket |> redirect(to: ~p"/games/#{room_id}")}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, reason)}
    end
  end
end
