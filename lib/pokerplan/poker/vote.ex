defmodule Pokerplan.Poker.Vote do
  alias Pokerplan.Poker.Vote, as: Vote

  @derive Jason.Encoder
  @enforce_keys [:label, :value]
  defstruct [:label, :value]

  @type t :: %__MODULE__{
          label: String.t(),
          value: term()
        }

  @spec cast_choices(binary()) :: :fibonacci | nil
  def cast_choices(input) when is_binary(input) do
    case input do
      "fibonacci" -> :fibonacci
      _ -> nil
    end
  end

  @spec list(atom()) :: [Vote.t()]
  def list({:fibonacci}) do
    [
      %Vote{value: :unsure, label: "?"},
      %Vote{value: 1, label: "1"},
      %Vote{value: 2, label: "2"},
      %Vote{value: 3, label: "3"},
      %Vote{value: 5, label: "5"},
      %Vote{value: 8, label: "8"},
      %Vote{value: 13, label: "13"},
      %Vote{value: 21, label: "21"},
      %Vote{value: 34, label: "34"},
      %Vote{value: 55, label: "55"},
      %Vote{value: 89, label: "89"},
      %Vote{value: :coffee_break, label: "☕️"}
    ]
  end

  @spec list(any()) :: []
  def list(_) do
    []
  end

  @spec can_count?(Vote.t()) :: boolean()
  def can_count?(%Vote{} = vote_choice), do: is_number(vote_choice.value)

  @spec coffee_break?(Vote.t()) :: boolean()
  def coffee_break?(%Vote{} = vote_choice), do: vote_choice.value == :coffee_break

  @spec unsure?(Vote.t()) :: boolean()
  def unsure?(%Vote{} = vote_choice), do: vote_choice.value == :unsure

  def choices do
    [Fibonacci: :fibonacci]
  end
end
