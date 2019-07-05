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
  end
end
