defmodule Knigge.BehaviourTest do
  use ExUnit.Case, async: true

  defmodule NormalBehaviour do
    @callback my_function() :: no_return
  end

  describe ".callbacks/1" do
    test "with a normal behaviour" do
      assert Knigge.Behaviour.callbacks(NormalBehaviour) == [my_function: 0]
    end

    test "with a module not defining `behaviour_info/1` (it's in compilation)" do
      defmodule BehaviourBeingCompiled do
        @callback my_great_function(arg :: any()) :: any()

        assert Knigge.Behaviour.callbacks(__MODULE__) == [my_great_function: 1]
      end
    end

    test "with duplicated callbacks" do
      defmodule DuplicatedBehaviour do
        @callback my_function(String.t()) :: no_return
        @callback my_function(atom()) :: no_return
        @optional_callbacks my_function: 1
        assert Knigge.Behaviour.callbacks(__MODULE__) == [my_function: 1]
        assert Knigge.Behaviour.optional_callbacks(__MODULE__) == [my_function: 1]
      end

      assert Knigge.Behaviour.callbacks(DuplicatedBehaviour) == [my_function: 1]
      assert Knigge.Behaviour.optional_callbacks(DuplicatedBehaviour) == [my_function: 1]
    end
  end
end
