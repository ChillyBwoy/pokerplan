defmodule Pokerplan.Poker.GameState do
  alias Pokerplan.Auth.User
  alias Pokerplan.Poker.GameState, as: GameState
  alias Pokerplan.Poker.Vote

  @derive Jason.Encoder
  @enforce_keys [:id, :title, :owner, :choices, :votes, :results, :created_at]
  defstruct [
    :id,
    :title,
    :owner,
    :show_results,
    :allow_reset,
    :votes,
    :average,
    :results,
    :choices,
    :created_at
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          owner: User.t(),
          show_results: boolean(),
          allow_reset: boolean(),
          votes: %{String.t() => String.t()},
          average: float() | nil,
          results: %{String.t() => integer()},
          choices: atom(),
          created_at: DateTime.t()
        }

  def(
    new(%{title: title, choices: choices, owner: %User{} = owner})
    when is_binary(title) and is_atom(choices)
  ) do
    id = Ecto.UUID.generate()

    dbg("New state: #{id}")

    %GameState{
      id: id,
      title: title,
      owner: owner,
      choices: choices,
      votes: %{},
      results: %{},
      created_at: DateTime.utc_now()
    }
  end

  def voted?(%GameState{} = state, username) when is_binary(username) do
    Map.has_key?(state.votes, username)
  end

  def vote(%GameState{} = state, username, value)
      when is_binary(username) and is_integer(value) do
    dbg("[game #{state.id}] '#{username}' votes for number '#{value}'")

    votes =
      if value == Map.get(state.votes, username),
        do: Map.delete(state.votes, username),
        else: Map.put(state.votes, username, value)

    %GameState{update(state) | votes: votes}
  end

  def reveal(%GameState{} = state) do
    dbg("[game #{state.id}] reveal")
    %GameState{update(state) | show_results: true}
  end

  def remove_player(%GameState{} = state, username) do
    dbg("[game #{state.id}] player '#{username}' removed")
    %GameState{update(state) | votes: Map.delete(state.votes, username)}
  end

  def reset(%GameState{} = state) do
    dbg("[game #{state.id}] reset")
    %GameState{state | show_results: false, votes: %{}, average: 0, results: %{}}
  end

  defp update(%GameState{} = state) do
    choices = Vote.list({state.choices})

    vote_values =
      state.votes
      |> Map.values()
      |> Enum.filter(&(Enum.at(choices, &1).value != 0))
      |> Enum.filter(&(not is_atom(&1)))

    size = length(vote_values)

    average = if size > 0, do: Enum.sum(vote_values) / size, else: 0

    results =
      state.votes
      |> Map.values()
      |> Enum.reduce(%{}, fn vote, acc ->
        Map.update(acc, vote, 1, &(&1 + 1))
      end)

    %GameState{state | average: average, results: results}
  end
end
