defmodule KV.Registry do
  @moduledoc """
  A registry of buckets implemented as a GenServer.
  """
  use GenServer

  @typedoc """
  A registry is a server that holds buckets.
  """
  @type registry :: pid

  @spec start_link([any]) :: {:ok, registry()}
  @doc """
  Starts the registry with given `opts`.
  `:name` is always required
  """
  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  @spec lookup(registry() | atom(), String.t()) :: {:ok, KV.Bucket.bucket()} | :error
  @doc """
  Retrieves the bucket `name` on the `registry` server.

  Returns `{:ok, pid}` if the buckets exists, `:error` otherwise.
  """
  def lookup(registry, name) do
    case :ets.lookup(registry, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> :error
    end
  end

  @spec create(registry(), String.t()) :: :ok
  @doc """
  Create a new bucket `name` on the `registry` server.
  """
  def create(registry, name) do
    GenServer.call(registry, {:create, name})
  end

  @impl true
  @spec init(atom) :: {:ok, {atom | :ets.tid(), %{}}}
  def init(table) do
    names = :ets.new(table, [:named_table, read_concurrency: true])
    refs = %{}
    {:ok, {names, refs}}
  end

  @impl true
  def handle_call({:create, name}, _from, reg = {names, refs}) do
    case lookup(names, name) do
      {:ok, bucket} ->
        {:reply, bucket, reg}

      :error ->
        {:ok, bucket} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
        ref = Process.monitor(bucket)
        :ets.insert(names, {name, bucket})
        refs = Map.put(refs, ref, name)
        {:reply, bucket, {names, refs}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    :ets.delete(names, name)
    {:noreply, {names, refs}}
  end

  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in KV.Registry: #{inspect(msg)}")
    {:noreply, state}
  end
end
