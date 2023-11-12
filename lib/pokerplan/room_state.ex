defmodule Pokerplan.RoomState do
  use GenServer

  @name __MODULE__

  def init(init_arg = %{}) do
    {:ok, init_arg}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end
end
