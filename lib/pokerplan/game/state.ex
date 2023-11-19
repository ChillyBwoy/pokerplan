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

  def voted?(state = %State{}, key) do
    Map.has_key?(state.votes, key)
  end

  def vote(state = %State{}, key, value) do
    prev_vote = Map.get(state.votes, key)

    if prev_vote == value do
      %State{state | votes: Map.delete(state.votes, key)}
    else
      %State{state | votes: Map.put(state.votes, key, value)}
    end
  end

  def show(state = %State{}) do
    %State{state | show_results: true}
  end

  def reset(state = %State{}) do
    %State{state | show_results: false, votes: %{}}
  end
end
