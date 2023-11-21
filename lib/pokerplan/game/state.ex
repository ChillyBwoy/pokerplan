defmodule Pokerplan.Game.State do
  alias Pokerplan.Auth.User
  alias Pokerplan.Game.State, as: State

  @enforce_keys [:title, :owner]
  @derive Jason.Encoder
  defstruct id: "",
            title: "",
            owner: %User{},
            show_results: false,
            votes: %{}

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
    %State{state | show_results: true}
  end

  def reset(%State{} = state) do
    %State{state | show_results: false, votes: %{}}
  end

  def results(%State{} = state) do
    state.votes
    |> Map.values()
    |> Enum.reduce(%{}, fn vote, acc ->
      Map.update(acc, vote, 1, &(&1 + 1))
    end)
  end

  def avg(%State{} = state) do
    size = state.votes |> Map.values() |> Enum.filter(&(&1 != 0)) |> length()

    case size do
      0 ->
        0

      _ ->
        state.votes
        |> Map.values()
        |> Enum.reduce(0, &(&1 + &2))
        |> div(size)
    end
  end
end
