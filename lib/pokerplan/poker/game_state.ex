defmodule Pokerplan.Poker.GameState do
  require Logger
  alias Pokerplan.Poker.GameState, as: GameState
  alias Pokerplan.Poker.Vote
  alias Pokerplan.Auth.User

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :id, :string
    field :title, :string
    field :choices, :string
    field :votes, {:map, :integer}, default: %{}
    field :results, {:map, :integer}, default: %{}
    field :show_results, :boolean, default: false
    field :average, :float, default: nil
    field :created_at, :utc_datetime
    embeds_one :creator, User, on_replace: :update
    embeds_one :owner, User, on_replace: :update
  end

  def changeset(%GameState{} = state, attrs) do
    state
    |> cast(attrs, [:id, :title, :choices, :votes, :results, :created_at])
    |> cast_embed(:creator, with: &User.changeset/2)
    |> cast_embed(:owner, with: &User.changeset/2)
    |> validate_required([:id, :title, :choices, :votes, :results, :created_at, :creator, :owner])
  end

  def create(%{title: title, creator: %User{} = creator, choices: choices})
      when is_binary(title) and is_binary(choices) do
    %GameState{}
    |> changeset(%{
      id: Ecto.UUID.generate(),
      title: title,
      choices: choices,
      votes: %{},
      results: %{},
      created_at: DateTime.utc_now(),
      creator: Map.from_struct(creator),
      owner: Map.from_struct(creator)
    })
    |> apply_action(:create)
  end

  def voted?(%GameState{} = state, username) when is_binary(username) do
    Map.has_key?(state.votes, username)
  end

  def vote(%GameState{} = state, username, value)
      when is_binary(username) and is_integer(value) do
    Logger.debug("[game:#{state.id}] '#{username}' votes for number '#{value}'")

    votes =
      if value == Map.get(state.votes, username),
        do: Map.delete(state.votes, username),
        else: Map.put(state.votes, username, value)

    %GameState{state | votes: votes} |> update()
  end

  def reveal(%GameState{} = state) do
    Logger.debug("[game:#{state.id}] reveal")
    %GameState{state | show_results: true} |> update()
  end

  def remove_player(%GameState{} = state, username) do
    Logger.debug("[game:#{state.id}] player '#{username}' removed")
    %GameState{state | votes: Map.delete(state.votes, username)} |> update()
  end

  def reset(%GameState{} = state) do
    Logger.debug("[game:#{state.id}] reset")
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
    choices = Vote.get_list(state.choices)

    values =
      state.votes
      |> Map.values()
      |> Enum.map(&Enum.at(choices, &1))
      |> Enum.filter(fn
        %Vote{} = vote -> not is_atom(vote.value)
        _ -> false
      end)
      |> Enum.map(& &1.value)

    size = length(values)
    if size > 0, do: (Enum.sum(values) / size) |> Float.round(2), else: nil
  end
end
