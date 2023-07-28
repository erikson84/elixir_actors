defmodule KV.Router do
  @doc """
  Dispatch the given `mod`, `fun`, `args` requests
  to the appropriate node based on `bucket`.
  """
  def route(bucket, mod, fun, args) do
    <<first, _rest::binary>> = bucket
    entry = Enum.find(table(), fn {enum, _node} -> first in enum end) || no_entry_error(bucket)

    if elem(entry, 1) == node() do
      apply(mod, fun, args)
    else
      {KV.RouterTasks, elem(entry, 1)}
      |> Task.Supervisor.async(KV.Router, :route, [bucket, mod, fun, args])
      |> Task.await()
    end
  end

  defp no_entry_error(bucket) do
    raise "could not find entry for #{inspect(bucket)} in table #{inspect(table())}"
  end

  @doc """
  The routing table
  """
  def table do
    [{?a..?m, :"foo@erikson-dell"}, {?n..?z, :"bar@erikson-dell"}]
  end
end
