defmodule Pokerplan.Auth.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Pokerplan.Auth.User

  @primary_key false
  embedded_schema do
    field :username, :string
    field :avatar_url, :string
  end

  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:username, :avatar_url])
    |> validate_required([:username, :avatar_url])
  end

  def create(%User{} = user, attrs) do
    user
    |> changeset(attrs)
    |> apply_action(:create)
  end
end
