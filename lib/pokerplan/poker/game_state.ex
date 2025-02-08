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

    %GameState{state | votes: votes} |> update()
  end

  def reveal(%GameState{} = state) do
    dbg("[game #{state.id}] reveal")
    %GameState{state | show_results: true} |> update()
  end

  def remove_player(%GameState{} = state, username) do
    dbg("[game #{state.id}] player '#{username}' removed")
    %GameState{state | votes: Map.delete(state.votes, username)} |> update()
  end

  def reset(%GameState{} = state) do
    dbg("[game #{state.id}] reset")
    %GameState{state | show_results: false, votes: %{}, average: 0, results: %{}}
  end

  defp update(%GameState{} = state) do
    average = votes_average(state)
    results = votes_results(state)

    %GameState{state | average: average, results: results}
  end

  defp votes_results(%GameState{} = state) do
    state.votes
    |> Map.values()
    |> Enum.reduce(%{}, fn vote, acc ->
      Map.update(acc, vote, 1, &(&1 + 1))
    end)
  end

  defp votes_average(%GameState{} = state) do
    choices = Vote.list({state.choices})

    votes =
      state.votes
      |> Map.values()
      |> Enum.map(&Enum.at(choices, &1))

    values =
      votes
      |> Enum.filter(fn
        %Vote{} = vote -> not is_atom(vote.value)
        _ -> false
      end)
      |> Enum.map(& &1.value)

    size = length(values)
    if size > 0, do: (Enum.sum(values) / size) |> Float.round(2), else: nil
  end
end
