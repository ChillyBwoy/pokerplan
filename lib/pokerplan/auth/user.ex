defmodule Pokerplan.Auth.User do
  @enforce_keys [:username, :avatar_url]
  defstruct [:username, :avatar_url]

  @type t :: %__MODULE__{
          username: String.t(),
          avatar_url: String.t()
        }
end
