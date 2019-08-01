defmodule ExCluster.ClusterConnector do
  use GenServer

  require Logger

  def init(_) do
    :net_kernel.monitor_nodes(true, node_type: :visible)
    {:ok, nil}
  end

  def child_spec(_args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [{}]},
      restart: :transient
    }
  end

  def start_link(_default) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def handle_info({:nodeup, _node, _type}, state) do
    set_members()
    {:noreply, state}
  end

  def handle_info({:nodedown, _node, _type}, state) do
    set_members()
    {:noreply, state}
  end

  defp set_members() do
    nodes = Enum.sort([Node.self() | Node.list()])
    Logger.info("**** Node list updated to #{inspect(nodes)}")

    Horde.Cluster.set_members(
      ExCluster.HordeSupervisor,
      Enum.map(nodes, fn n -> {ExCluster.HordeSupervisor, n} end)
    )

    Horde.Cluster.set_members(
      ExCluster.HordeRegistry,
      Enum.map(nodes, fn n -> {ExCluster.HordeRegistry, n} end)
    )
  end
end
