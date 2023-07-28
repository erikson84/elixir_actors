defmodule KV.Bucket do
  @moduledoc """
  Implements a `bucket` type with basic `get/2` and `put/2` methods for updating.
  """
  use Agent, restart: :temporary

  @typedoc """
  The PID of a state-keeping bucket.
  """
  @type bucket :: pid()

  @spec start_link([any]) :: {:error, any} | {:ok, pid}
  @doc """
  Initiate the bucket with an initial `init` list.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end

  @spec put(bucket(), String.t(), pos_integer()) :: :ok
  @doc """
  Updates the `bucket` list with the new or existing `item` and `quantity`.
  """
  def put(bucket, item, quantity) do
    Agent.update(
      bucket,
      &Map.update(&1, item, quantity, fn old_quantity -> old_quantity + quantity end)
    )
  end

  @spec get(bucket(), String.t()) :: any
  @doc """
  Gets the amount of `item`in `bucket`.
  """
  def get(bucket, item) do
    Agent.get(bucket, &Map.get(&1, item))
  end

  @doc """
  Delete `item` from `bucket` and returns it, if it exists.
  """
  def delete(bucket, item) do
    Agent.get_and_update(bucket, &Map.pop(&1, item))
  end
end
