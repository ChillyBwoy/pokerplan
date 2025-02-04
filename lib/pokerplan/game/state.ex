defmodule Pokerplan.Game.State do
  alias Pokerplan.Auth.User
  alias Pokerplan.Game.State, as: State
  alias Pokerplan.Game.VoteChoice, as: VoteChoice

  @enforce_keys [:title, :owner, :choices]
  @derive Jason.Encoder
  defstruct id: "",
            title: "",
            owner: %User{},
            show_results: false,
            allow_reset: false,
            votes: %{},
            average: nil,
            results: %{},
            choices: nil,
            created_at: DateTime.utc_now()

  def new(%{title: title, choices: choices, owner: owner = %User{}})
      when is_binary(title) and is_atom(choices) do
    id = Ecto.UUID.generate()

    %State{
      id: id,
      title: title,
      owner: owner,
      choices: choices,
      created_at: DateTime.utc_now()
    }
  end

  def voted?(%State{} = state, username) when is_binary(username) do
    Map.has_key?(state.votes, username)
  end

  def vote(%State{} = state, username, value) when is_binary(username) do
    prev_vote = Map.get(state.votes, username)

    case value do
      ^prev_vote -> %State{state | votes: Map.delete(state.votes, username)}
      _ -> %State{state | votes: Map.put(state.votes, username, value)}
    end
  end

  def show(%State{} = state) do
    choices = VoteChoice.list({state.choices})

    vote_values =
      state.votes
      |> Map.values()
      |> Enum.filter(&(Enum.at(choices, &1).value != 0))
      |> Enum.filter(&(not is_atom(&1)))

    ccc = state.votes |> Map.values() |> Enum.map(&Enum.at(choices, &1).value)

    dbg(ccc)

    size = length(vote_values)

    average = if size > 0, do: Enum.sum(vote_values) / size, else: 0

    results =
      state.votes
      |> Map.values()
      |> Enum.reduce(%{}, fn vote, acc ->
        Map.update(acc, vote, 1, &(&1 + 1))
      end)

    %State{state | show_results: true, average: average, results: results}
  end

  def reset(%State{} = state) do
    %State{state | show_results: false, votes: %{}, average: 0, results: %{}}
  end

  def remove_player(%State{} = state, username) do
    %State{state | votes: Map.delete(state.votes, username)}
  end
end
