defmodule Pokerplan.Game.State do
  alias Pokerplan.Auth.User
  alias Pokerplan.Game.State, as: State
  alias Pokerplan.Game.VoteChoice, as: VoteChoice

  @enforce_keys [:title, :owner]
  @derive Jason.Encoder
  defstruct id: "",
            title: "",
            owner: %User{},
            show_results: false,
            votes: %{},
            average: 0,
            results: %{},
            choices: "fibonacci"

  def new(%{title: title, owner: owner = %User{}}) do
    id = UUID.uuid4(:hex)

    %State{
      id: id,
      title: title,
      owner: owner
    }
  end

  def voted?(%State{} = state, key) do
    Map.has_key?(state.votes, key)
  end

  def vote(%State{} = state, key, value) do
    prev_vote = Map.get(state.votes, key)

    if prev_vote == value do
      %State{state | votes: Map.delete(state.votes, key)}
    else
      %State{state | votes: Map.put(state.votes, key, value)}
    end
  end

  def show(%State{} = state) do
    # TODO: make this configurable
    choices = VoteChoice.list({:fibonacci})

    size =
      state.votes
      |> Map.values()
      |> Enum.filter(&(Enum.at(choices, &1).value != 0))
      |> length()

    sum =
      state.votes
      |> Map.values()
      |> Enum.reduce(0, &(Enum.at(choices, &1).value + &2))

    average = if size > 0, do: sum / size, else: 0

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
