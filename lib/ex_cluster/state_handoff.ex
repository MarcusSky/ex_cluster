defmodule ExCluster.StateHandoff do
  use GenServer

  require Logger

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(args) do
    {:ok, args}
  end

  # store a key and content in the handoff storage
  def handoff(key, content) do
    GenServer.call(__MODULE__, {:handoff, key, content})
  end

  # pickup the stored content data for a key
  def pickup(key) do
    GenServer.call(__MODULE__, {:pickup, key})
  end

  def handle_call({:handoff, key, content}, _from, state) do
    case Redix.command(ExCluster.Redix, ["SET", state_key(key), content]) do
      {:ok, "OK"} ->
        Logger.info("Added #{key}'s content #{inspect(content)} to storage")
        {:reply, :ok, state}

      _ ->
        Logger.error("Error to add #{key}'s content #{inspect(content)} to storage")
        {:reply, :error, state}
    end
  end

  def handle_call({:pickup, key}, _from, state) do
    case Redix.command(ExCluster.Redix, ["GET", state_key(key)]) do
      {:ok, content} when not is_nil(content) ->
        Logger.info("Picked up #{inspect(content, charlists: :as_lists)} for #{key}")
        GenServer.cast(__MODULE__, {:remove, key})
        {:reply, content, state}

      _ ->
        Logger.info("Did not find anything for #{key}, returning nil")
        {:reply, nil, state}
    end
  end

  def handle_cast({:remove, key}, state) do
    case Redix.command(ExCluster.Redix, ["DEL", state_key(key)]) do
      {:ok, 0} ->
        Logger.info("Did not find #{inspect(key)} on storage")
        {:noreply, state}

      {:ok, _number_of_keys} ->
        Logger.info("Removed #{inspect(key)} from storage")
        {:noreply, state}

      _ ->
        Logger.info("Error when trying to remove \"#{key}\"")
        {:noreply, state}
    end
  end

  defp state_key(key), do: "key-state-#{key}"
end
