defmodule Knigge.ModuleTest do
  use ExUnit.Case, async: true

  alias Knigge.Module

  describe ".exists?/1" do
    test "returns false for a non-existing module" do
      assert Module.exists?(This.Does.Not.Exist) == false
    end

    test "returns true for an existing module" do
      assert Module.exists?(Knigge) == true
    end
  end
end
