defmodule PokerplanWeb.LobbyLive do
  use PokerplanWeb, :live_view

  alias Phoenix.PubSub

  alias Pokerplan.Auth.User
  alias Pokerplan.Game.Server, as: GameServer
  alias Pokerplan.Game.State, as: GameState
  alias Pokerplan.Game.Supervisor, as: GameSupervisor
  alias PokerplanWeb.Presence

  @presence_topic {:lobby}

  def mount(_params, _session, socket = %{assigns: %{current_user: %User{} = user}}) do
    Presence.track_user(@presence_topic, user)
    PubSub.subscribe(Pokerplan.PubSub, Presence.get_topic(@presence_topic))
    PubSub.subscribe(Pokerplan.PubSub, GameServer.get_topic())

    {:ok,
     socket
     |> assign(:users, Presence.user_list(@presence_topic))
     |> assign(:games, GameSupervisor.list_games())
     |> assign(:errors, %{})
     |> assign(:form, create_form())}
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

  def handle_event("validate", form = %{"title" => _title}, socket) do
    {:noreply, socket |> assign(:errors, validate_form(form))}
  end

  def handle_event(
        "save",
        %{"title" => title},
        socket = %{assigns: %{current_user: %User{} = current_user}}
      ) do
    case GameSupervisor.start_new_game(%{title: title, owner: current_user}) do
      {:ok, room_id} ->
        {:noreply, socket |> redirect(to: ~p"/games/#{room_id}")}

      {:error, reason} ->
        {:noreply, socket |> put_flash(:error, reason)}
    end
  end

  defp create_form() do
    %{"title" => ""} |> to_form()
  end

  defp validate_form(form) do
    errors =
      %{}
      |> validate_field(form, :title)

    if map_size(errors) == 0 do
      {:ok}
    else
      {:error, errors}
    end
  end

  defp validate_field(%{} = errors, form, field) do
    cond do
      Map.get(form, Atom.to_string(field), "") == "" ->
        Map.put(errors, field, ["can't be blank"])

      true ->
        errors
    end
  end
end
