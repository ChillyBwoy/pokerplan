defmodule PokerplanWeb.LobbyLive do
  use PokerplanWeb, :live_view

  alias Pokerplan.Auth.User
  alias Pokerplan.Poker.CardTable
  alias Pokerplan.Poker.GameState
  alias Pokerplan.Poker.Vote
  alias Pokerplan.Poker.Supervisor, as: PokerSupervisor
  alias Pokerplan.Poker.NewGameForm
  alias PokerplanWeb.Presence

  def mount(_params, _session, socket = %{assigns: %{current_user: %User{} = current_user}}) do
    # We don't care if the presence tracking fails
    Presence.track_user({:lobby}, current_user)
    :ok = Presence.subscribe({:lobby})
    :ok = CardTable.subscribe({:list})

    form =
      %NewGameForm{}
      |> NewGameForm.changeset(%{})
      |> to_form(as: :game_form)

    {:ok,
     socket
     |> assign(:users, Presence.get_users_in_lobby())
     |> assign(:games, PokerSupervisor.list_games())
     |> assign(:choices, Vote.choices())
     |> assign(:form, form)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        socket = %{assigns: %{users: users}}
      ) do
    next_users = users |> Presence.map_presence(joins, leaves)
    {:noreply, assign(socket, :users, next_users)}
  end

  def handle_info({:game_start, %GameState{}}, socket) do
    {:noreply, assign(socket, :games, PokerSupervisor.list_games())}
  end

  def handle_info({:game_end, %GameState{}}, socket) do
    {:noreply, assign(socket, :games, PokerSupervisor.list_games())}
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
        "create",
        %{"game_form" => %{"title" => title, "choices" => choices}},
        socket = %{assigns: %{current_user: %User{} = current_user}}
      ) do
    case PokerSupervisor.start_new_game(%{title: title, creator: current_user, choices: choices}) do
      {:ok, _pid, %GameState{} = state} ->
        {:noreply, socket |> redirect(to: ~p"/games/#{state.id}")}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, reason)}
    end
  end
end
