defmodule ExCluster.OrderStarter do
  use GenServer

  require Logger

  def child_spec(_args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [[]]},
      restart: :transient
    }
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_) do
    Horde.Supervisor.start_child(ExCluster.HordeSupervisor, {ExCluster.Order, "John"})
    Horde.Supervisor.start_child(ExCluster.HordeSupervisor, {ExCluster.Order, "Karen"})
    Horde.Supervisor.start_child(ExCluster.HordeSupervisor, {ExCluster.Order, "Marcus"})
    Horde.Supervisor.start_child(ExCluster.HordeSupervisor, {ExCluster.Order, "Guimas"})
    Horde.Supervisor.start_child(ExCluster.HordeSupervisor, {ExCluster.Order, "Vivia"})
    {:ok, nil}
  end
end
