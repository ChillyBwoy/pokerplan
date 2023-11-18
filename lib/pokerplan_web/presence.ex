defmodule PokerplanWeb.Presence do
  use Phoenix.Presence,
    otp_app: :app,
    pubsub_server: Pokerplan.PubSub

  alias Pokerplan.Auth.User

  def get_topic(%{room_id: id}), do: "presence:room:#{id}"
  def get_topic({:lobby}), do: "presence:lobby"

  def user_list(topic) do
    initial = topic |> get_topic() |> list()
    map_joins(%{}, initial)
  end

  def init(_opts), do: {:ok, %{}}

  def track_user(topic, user = %User{}) do
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
end
