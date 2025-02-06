defmodule Pokerplan.Poker.CardTable do
  use GenServer, restart: :transient

  alias Phoenix.PubSub
  alias Pokerplan.Poker.GameState

  # 30 minutes
  @timeout 1_000 * 60 * 30

  def start_link(%GameState{} = initial_state) do
    GenServer.start_link(__MODULE__, initial_state, name: get_name(initial_state.id))
  end

  @impl true
  def init(%GameState{} = initial_state) do
    :ok = PubSub.broadcast(Pokerplan.PubSub, get_topic({:list}), {:game_start, initial_state})
    {:ok, initial_state, @timeout}
  end

  def stop(id) do
    get_name(id) |> GenServer.stop()
  end

  def active?(id) do
    case GenServer.whereis(get_name(id)) do
      nil -> false
      _ -> true
    end
  end

  def current(id) do
    get_name(id) |> GenServer.call({:current})
  end

  def dispatch({:vote, id: id, username: username, value: value}) do
    get_name(id) |> GenServer.call({:vote, username, value})
  end

  def dispatch({:reveal, id: id}) do
    get_name(id) |> GenServer.call({:reveal})
  end

  def dispatch({:reset, id: id}) do
    get_name(id) |> GenServer.call({:reset})
  end

  def dispatch({:player_leave, id: id, username: username}) do
    get_name(id) |> GenServer.call({:player_leave, username})
  end

  def subscribe(topic) do
    case PubSub.subscribe(Pokerplan.PubSub, get_topic(topic)) do
      :ok -> :ok
      {:error, _} -> {:error, "Failed to subscribe to game server"}
    end
  end

  # Callbacks

  @impl true
  def handle_call({:current}, _from, state) do
    reply(state)
  end

  @impl true
  def handle_call({:vote, username, value}, _from, %GameState{} = state) do
    GameState.vote(state, username, value) |> reply({:notify})
  end

  @impl true
  def handle_call({:reveal}, _from, %GameState{} = state) do
    GameState.reveal(state) |> reply({:notify})
  end

  @impl true
  def handle_call({:reset}, _from, %GameState{} = state) do
    GameState.reset(state) |> reply({:notify})
  end

  @impl true
  def handle_call({:player_leave, username}, _from, %GameState{} = state) do
    GameState.remove_player(state, username) |> reply({:notify})
  end

  @impl true
  def handle_info(:timeout, state) do
    :ok = PubSub.broadcast(Pokerplan.PubSub, get_topic({:list}), {:game_end, state})
    {:stop, :normal, state}
  end

  # Private funcs

  defp reply(%GameState{} = state) do
    {:reply, state, state, @timeout}
  end

  defp reply(%GameState{} = state, {:notify}) do
    :ok = PubSub.broadcast(Pokerplan.PubSub, get_topic({:game, state.id}), {:game_state, state})
    {:reply, state, state, @timeout}
  end

  defp get_name(game_id), do: {:via, Registry, {Pokerplan.Registry, "poker_game_#{game_id}"}}

  defp get_topic({:game, game_id}) when is_binary(game_id) do
    "games:game:#{game_id}"
  end

  defp get_topic({:list}), do: "games:list"
end
