defmodule Kv.RouterTest do
  use ExUnit.Case, async: true

  test "route requests across nodes" do
    assert KV.Router.route("hello", Kernel, :node, []) == :"foo@erikson-dell"
    assert KV.Router.route("world", Kernel, :node, []) == :"bar@erikson-dell"
  end

  test "raises on unknown entried" do
    assert_raise RuntimeError, ~r/could not find entry/, fn -> KV.Router.route(<<0>>, Kernel, :node, [])
  end
end
