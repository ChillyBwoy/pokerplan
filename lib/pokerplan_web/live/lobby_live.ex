defmodule PokerplanWeb.LobbyLive do
  use PokerplanWeb, :live_view
  alias Pokerplan.RoomState

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:form, create_form())}
  end

  def handle_event("validate", %{"title" => _title}, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"title" => title}, socket) do
    case RoomState.create_new_room(%{title: title}) do
      {:ok, room_id} ->
        {:noreply, socket |> redirect(to: "/rooms/#{room_id}")}

      _ ->
        {:noreply, socket}
    end
  end

  defp create_form() do
    %{"title" => ""} |> to_form()
  end
end
