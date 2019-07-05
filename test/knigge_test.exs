defmodule KniggeTest do
  use ExUnit.Case
  doctest Knigge

  test "greets the world" do
    assert Knigge.hello() == :world
  end
end
