defmodule Pokerplan.Game.VoteChoice do
  @derive Jason.Encoder
  defstruct [
    :label,
    :value
  ]
end
