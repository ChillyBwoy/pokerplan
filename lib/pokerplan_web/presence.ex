defmodule PokerplanWeb.Presence do
  use Phoenix.Presence,
    otp_app: :app,
    pubsub_server: Pokerplan.PubSub

  alias Phoenix.PubSub
  alias Pokerplan.Auth.User

  def init(_opts) do
    {:ok, %{}}
  end

  def track_user(topic, %User{} = user) do
    track(self(), get_topic(topic), user.username, %{
      user: user,
      online_at: inspect(System.system_time(:millisecond))
    })
  end

  def untrack_user(topic, username),
    do: untrack(self(), get_topic(topic), username)

  def map_presence(target = %{}, joins, leaves) do
    target
    |> map_joins(joins)
    |> map_leaves(leaves)
  end

  def get_users_in_lobby() do
    map_joins(%{}, get_topic({:lobby}) |> list())
  end

  def get_users_in_game(game_id) when is_binary(game_id) do
    map_joins(%{}, get_topic({:game, game_id}) |> list())
  end

  def subscribe(topic) do
    case PubSub.subscribe(Pokerplan.PubSub, get_topic(topic)) do
      :ok -> :ok
      {:error, _} -> {:error, "Failed to subscribe to presence"}
    end
  end

  def unsubscribe(topic) do
    PubSub.unsubscribe(Pokerplan.PubSub, get_topic(topic))
  end

  # Private API

  defp map_joins(target = %{}, joins) do
    Enum.reduce(joins, target, fn {username, %{metas: metas}}, target ->
      Map.put(target, username, hd(metas).user)
    end)
  end

  defp map_leaves(target = %{}, leaves) do
    Enum.reduce(leaves, target, fn {user_id, _}, target ->
      Map.delete(target, user_id)
    end)
  end

  defp get_topic({:lobby}), do: "presence:lobby"

  defp get_topic({:game, game_id}) when is_binary(game_id) do
    "presence:game:#{game_id}"
  end
end
