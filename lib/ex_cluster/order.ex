defmodule ExCluster.Order do
  use GenServer

  require Logger

  def test do
    ExCluster.Order.add("Karan", [2, 3])
    ExCluster.Order.add("John", [1, 2])
  end

  def test_contents do
    ExCluster.Order.contents("Karan")
    ExCluster.Order.contents("John")
  end

  def child_spec(customer), do: %{id: customer, start: {__MODULE__, :start_link, [customer]}}

  def start_link(customer) do
    Logger.info("Starting Order for #{customer}")
    # note the change here in providing a name: instead of [] as the 3rd param
    GenServer.start_link(__MODULE__, customer, name: via_tuple(customer))
  end

  # add contents to the customers order
  def add(customer, new_order_contents) do
    GenServer.cast(via_tuple(customer), {:add, new_order_contents})
  end

  # fetch current contents of the customers order
  def contents(customer) do
    GenServer.call(via_tuple(customer), {:contents})
  end

  defp via_tuple(customer) do
    {:via, Horde.Registry, {ExCluster.HordeRegistry, customer}}
  end

  def init(customer) do
    Process.flag(:trap_exit, true)
    {:ok, customer, {:continue, :load_state}}
  end

  def handle_continue(:load_state, customer) do
    case ExCluster.StateHandoff.pickup(customer) do
      nil ->
        {:noreply, {customer, []}}

      content ->
        order_contents = deserialize_content(content)
        {:noreply, {customer, order_contents}}
    end
  end

  def handle_info({:EXIT, _pid, {:name_conflict, state, _registry, _horde_pid}}, state) do
    Logger.info(
      "Tried to start a process with the name: #{inspect(state)} that is already started."
    )

    {:noreply, state}
  end

  def handle_info(message, state) do
    Logger.info("Received: #{inspect(message)}")
    {:noreply, state}
  end

  def handle_cast({:add, new_order_contents}, {customer, order_contents}) do
    {:noreply, {customer, order_contents ++ new_order_contents}}
  end

  def handle_call({:contents}, _from, state = {_, order_contents}) do
    {:reply, order_contents, state}
  end

  def terminate(_reason, {customer, order_contents}) do
    Logger.info("Saving #{inspect(inspect(order_contents, charlists: :as_lists))}")
    ExCluster.StateHandoff.handoff(customer, serialize_content(order_contents))
    :ok
  end

  defp serialize_content(content), do: Jason.encode!(content)
  defp deserialize_content(content), do: Jason.decode!(content)
end
