defmodule PokerplanWeb.UserComponents do
  use Phoenix.Component
  alias Pokerplan.Auth.User
  use Gettext, backend: PokerplanWeb.Gettext

  embed_templates "user_components/*"

  attr :class, :string, default: nil
  attr :user, User, required: true
  slot :slot_before
  slot :slot_after
  def user_avatar(assigns)

  attr :class, :string, default: nil
  attr :size, :string, values: ["m", "l"], default: "m"
  attr :state, :string, values: ["idle", "done"], default: "idle"
  attr :flipped, :boolean, default: false, doc: "Whether the card is flipped or not"
  attr :active, :boolean, default: false, doc: "Whether the card is hovered or not"
  attr :rest, :global, include: ~w(disabled form name value)
  slot :inner_block
  def playing_card(assigns)

  attr :class, :string, default: nil
  slot :inner_block
  def layout(assigns)

  attr :title, :string, required: true
  slot :inner_block
  def card(assigns)
end
