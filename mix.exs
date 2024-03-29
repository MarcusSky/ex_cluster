defmodule ExCluster.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_cluster,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        ex_cluster: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent]
        ]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExCluster, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:horde, "~> 0.6.0"},
      {:libcluster, "~> 3.1"},
      {:redix, ">= 0.0.0"},
      {:jason, "~> 1.1"}
    ]
  end
end
