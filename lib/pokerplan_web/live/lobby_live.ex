defmodule PokerplanWeb.LobbyLive do
  use PokerplanWeb, :live_view

  alias Phoenix.PubSub

  alias Pokerplan.Auth.User
  alias Pokerplan.Game.Supervisor, as: GameSupervisor
  alias PokerplanWeb.Presence

  @presence_topic {:lobby}

  def mount(_params, _session, socket = %{assigns: %{current_user: %User{} = user}}) do
    Presence.track_user(@presence_topic, user)
    PubSub.subscribe(Pokerplan.PubSub, Presence.get_topic(@presence_topic))

    list_of_children = DynamicSupervisor.which_children(GameSupervisor)

    IO.inspect(list_of_children)

    {:ok,
     socket
     |> assign(:users, Presence.user_list(@presence_topic))
     |> assign(:form, create_form())}
  end

  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        socket = %{assigns: %{users: users}}
      ) do
    next_users = users |> Presence.map_presence(joins, leaves)
    {:noreply, assign(socket, :users, next_users)}
  end

  def handle_event("validate", %{"title" => _title}, socket) do
    # TODO: add validation
    {:noreply, socket}
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
end
