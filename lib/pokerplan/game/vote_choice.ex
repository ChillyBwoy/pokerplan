defmodule Pokerplan.Game.VoteChoice do
  alias Pokerplan.Game.VoteChoice, as: VoteChoice

  @enforce_keys [:label, :value]
  @derive Jason.Encoder
  defstruct [
    :label,
    :value
  ]

  def cast_choices(input) when is_binary(input) do
    case input do
      "fibonacci" -> :fibonacci
      _ -> nil
    end
  end

  def list({:fibonacci}) do
    [
      %VoteChoice{value: :unsure, label: "?"},
      %VoteChoice{value: 1, label: "1"},
      %VoteChoice{value: 2, label: "2"},
      %VoteChoice{value: 3, label: "3"},
      %VoteChoice{value: 5, label: "5"},
      %VoteChoice{value: 8, label: "8"},
      %VoteChoice{value: 13, label: "13"},
      %VoteChoice{value: 21, label: "21"},
      %VoteChoice{value: 34, label: "34"},
      %VoteChoice{value: 55, label: "55"},
      %VoteChoice{value: 89, label: "89"},
      %VoteChoice{value: :coffee_break, label: "☕️"}
    ]
  end

  def list(_) do
    []
  end

  def choices do
    [Fibonacci: :fibonacci]
  end
end
