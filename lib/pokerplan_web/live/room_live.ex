defmodule PokerplanWeb.RoomLive do
  use PokerplanWeb, :live_view

  alias PokerplanWeb.Presence

  @impl true
  def mount(_params, _session, socket) do
    send(self(), :after_join)
    # {:ok, assign(socket, form: new_form())}
    {:ok, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.user_id, %{
        username: socket.assigns.username,
        online_at: inspect(System.system_time(:millisecond))
      })

    {:noreply, socket}
  end

  # @impl true
  # def handle_event("validate", %{"name" => name}, socket) do
  #   {:noreply, socket}
  # end

  # def handle_event("submit", %{"name" => name}, socket) do
  #   {:noreply, socket}
  # end

  # defp new_form do
  #   fields = %{"name" => ""}
  #   errors = [name: "Can't be blank"]

  #   to_form(fields, errors)
  # end
end
