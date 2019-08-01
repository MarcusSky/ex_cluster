defmodule ExCluster do
  use Application

  require Logger

  def start(_type, _args) do
    Logger.info("ExCluster application started")

    topologies = [
      ex_cluster: [
        strategy: Elixir.Cluster.Strategy.DNSPoll,
        config: [query: "tasks.t_ex_cluster_demo", node_basename: "ex_cluster"]
      ]
    ]

    children = [
      {Cluster.Supervisor, [topologies, [name: ExCluster.ClusterSupervisor]]},
      {Redix, host: "redis", name: ExCluster.Redix},
      ExCluster.StateHandoff,
      {Horde.Registry, [name: ExCluster.HordeRegistry, keys: :unique]},
      {Horde.Supervisor,
       [name: ExCluster.HordeSupervisor, shutdown: 1000, strategy: :one_for_one]},
      {ExCluster.ClusterConnector, restart: :transient},
      ExCluster.OrderStarter
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: ExCluster.Supervisor)
  end
end
