defmodule PokerplanWeb.UserComponents do
  use Phoenix.Component

  alias Pokerplan.Auth.User

  attr :class, :string, default: nil
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
    <span class={["inline-flex items-center gap-2", @class]}>
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

  attr :class, :string, default: nil
  attr :size, :string, values: ["m", "l"], default: "m"
  attr :state, :string, values: ["idle", "open", "done"], default: "idle"
  attr :active, :boolean, default: false, doc: "Whether the card is hovered or not"
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block

  def playing_card(assigns) do
    ~H"""
    <button
      class={[
        "flex items-center justify-center text-white rounded-lg border-2 box-border shadow-lg transition-transform font-bold",
        @size == "m" && "w-16 h-24 text-3xl",
        @size == "l" && "w-24 h-36 text-4xl",
        @active && "hover:scale-110 hover:-translate-y-2 cursor-pointer",
        !@active && "cursor-default",
        @state == "idle" && "bg-gray-400 border-gray-500",
        @state == "open" && "bg-blue-400 border-blue-500",
        @state == "done" && "bg-green-400 border-green-500",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end
end
