defmodule KV.RegistryTest do
  use ExUnit.Case, async: true

  setup context do
    _ = start_supervised!({KV.Registry, name: context.test})
    %{reg: context.test}
  end

  test "empty registry returns `:error` on lookup", %{reg: reg} do
    assert KV.Registry.lookup(reg, "shop") == :error
  end

  test "create a bucket on registry and return it on lookup", %{reg: reg} do
    KV.Registry.create(reg, "shop")
    assert {:ok, bucket} = KV.Registry.lookup(reg, "shop")
    assert KV.Bucket.put(bucket, "milk", 3) == :ok
    assert KV.Bucket.get(bucket, "milk") == 3
  end

  test "removes buckets on exit", %{reg: reg} do
    KV.Registry.create(reg, "shopping")
    {:ok, bucket} = KV.Registry.lookup(reg, "shopping")
    Agent.stop(bucket)
    _ = KV.Registry.create(reg, "bogus")
    assert KV.Registry.lookup(reg, "shopping") == :error
  end

  test "removes bucket on crash", %{reg: reg} do
    KV.Registry.create(reg, "shopping")
    {:ok, bucket} = KV.Registry.lookup(reg, "shopping")

    # Stop the bucket with non-normal reason
    Agent.stop(bucket, :shutdown)
    _ = KV.Registry.create(reg, "bogus")
    assert KV.Registry.lookup(reg, "shopping") == :error
  end

  test "bucket can crash at any time", %{reg: reg} do
    KV.Registry.create(reg, "shopping")
    {:ok, bucket} = KV.Registry.lookup(reg, "shopping")

    # Simulate a bucket crash by explicitly and synchronously shutting it down
    Agent.stop(bucket, :shutdown)

    # Now trying to call the dead process causes a :noproc exit
    catch_exit(KV.Bucket.put(bucket, "milk", 3))
  end
end
