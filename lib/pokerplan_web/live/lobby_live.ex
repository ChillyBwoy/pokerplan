defmodule PokerplanWeb.LobbyLive do
  use PokerplanWeb, :live_view

  alias Phoenix.PubSub

  alias Pokerplan.Auth.User
  alias Pokerplan.Game.Server, as: GameServer
  alias Pokerplan.Game.State, as: GameState
  alias Pokerplan.Game.Supervisor, as: GameSupervisor
  alias Pokerplan.Game.NewGameForm
  alias PokerplanWeb.Presence

  @presence_topic {:lobby}

  def mount(_params, _session, socket = %{assigns: %{current_user: %User{} = user}}) do
    Presence.track_user(@presence_topic, user)
    PubSub.subscribe(Pokerplan.PubSub, Presence.get_topic(@presence_topic))
    PubSub.subscribe(Pokerplan.PubSub, GameServer.get_topic())

    form =
      %NewGameForm{}
      |> NewGameForm.changeset(%{})
      |> to_form(as: :game_form)

    {:ok,
     socket
     |> assign(:users, Presence.user_list(@presence_topic))
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
