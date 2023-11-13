defmodule PokerplanWeb.UserComponents do
  use Phoenix.Component
  alias Pokerplan.Auth.User

  attr :user, User, required: true
  attr :size, :string, values: ["xl", "m", "s"], default: "m"
  slot :slot_before
  slot :slot_after

  def user_avatar(assigns) do
    icon_size =
      case assigns.size do
        "xl" -> 48
        "m" -> 32
        "s" -> 24
        nil -> 32
      end

    assigns = assign_new(assigns, :image_size, fn -> icon_size end)

    ~H"""
    <span class="inline">
      <span :if={@slot_before != []}>
        <%= render_slot(@slot_before) %>
      </span>
      <img
        src={@user.avatar_url}
        alt={@user.username}
        width={@image_size}
        height={@image_size}
        class="inline rounded-full border border-2 border-blue-500"
      />
      <span :if={@slot_after != []}>
        <%= render_slot(@slot_after) %>
      </span>
    </span>
    """
  end
end
