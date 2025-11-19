defmodule ChromicClientTest do
  use ExUnit.Case
  doctest ChromicClient

  test "greets the world" do
    assert ChromicClient.hello() == :world
  end
end
