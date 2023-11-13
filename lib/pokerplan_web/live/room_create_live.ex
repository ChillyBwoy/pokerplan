defmodule PokerplanWeb.RoomCreateLive do
  use PokerplanWeb, :live_view
  # alias Pokerplan.RoomState
  # alias Phoenix.PubSub

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:form, create_form())}
  end

  def handle_event("validate", %{"title" => _title}, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"title" => _title}, socket) do
    {:noreply, socket |> redirect(to: "/rooms/#{UUID.uuid4()}")}
  end

  defp create_form() do
    %{title: ""} |> to_form()
  end
end
