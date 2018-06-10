defmodule LibkvmTest do
  use ExUnit.Case
  doctest Libkvm

  test "greets the world" do
    assert Libkvm.hello() == :world
  end
end
