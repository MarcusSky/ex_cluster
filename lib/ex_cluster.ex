defmodule ExCluster do
  use Application
  require Logger

  # add a application start callback function
  def start(_type, _args) do
    Logger.info("ExCluster application started")

    case System.get_env("NODES") do
      nodes when is_binary(nodes) ->
        nodes
        # convert list of nodes into atoms of node names
        |> String.split(",")
        |> Enum.map(&String.to_atom/1)
        # connect to all nodes to make a cluster
        |> Enum.each(&Node.connect/1)

      _ ->
        nil
    end

    children = [
      {ExCluster.StateHandoff, []},
      {Horde.Registry, [name: ExCluster.Registry, keys: :unique, members: registry_members()]},
      {Horde.Supervisor,
       [
         name: ExCluster.OrderSupervisor,
         shutdown: 1000,
         strategy: :one_for_one,
         members: supervisor_members()
       ]},
      %{
        id: ExCluster.ClusterConnector,
        restart: :transient,
        start:
          {Task, :start_link,
           [
             fn ->
               Horde.Supervisor.wait_for_quorum(ExCluster.OrderSupervisor, 30_000)

               Enum.each(Node.list(), fn node ->
                 :ok = ExCluster.StateHandoff.join(node)
               end)
             end
           ]}
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: ExCluster.Supervisor)
  end

  defp registry_members do
    [Node.self() | Node.list()]
    |> Enum.map(fn node -> {ExCluster.Registry, node} end)
  end

  defp supervisor_members do
    [Node.self() | Node.list()]
    |> Enum.map(fn node -> {ExCluster.OrderSupervisor, node} end)
  end
end
