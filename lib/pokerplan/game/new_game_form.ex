defmodule Pokerplan.Game.NewGameForm do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields [:title]

  schema "new_game_form" do
    field(:title, :string)
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
