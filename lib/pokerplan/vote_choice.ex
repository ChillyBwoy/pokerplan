defmodule Pokerplan.VoteChoice do
  @derive Jason.Encoder
  defstruct [
    :label,
    :value
  ]
end
