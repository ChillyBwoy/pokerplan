defmodule PokerplanWeb.RoomCreateLive do
  use PokerplanWeb, :live_view
  alias Pokerplan.RoomState
  # alias Phoenix.PubSub

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:form, create_form())}
  end

  def handle_event("validate", %{"title" => _title}, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"title" => title}, socket) do
    room_id = UUID.uuid4(:hex)

    case RoomState.start(%{room_id: room_id, title: title}) do
      {:ok, _pid} ->
        {:noreply, socket |> redirect(to: "/rooms/#{room_id}")}

      _ ->
        {:noreply, socket}
    end
  end

  defp create_form() do
    %{title: ""} |> to_form()
  end
end
