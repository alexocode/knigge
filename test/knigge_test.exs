defmodule KniggeTest do
  use ExUnit.Case, async: true

  describe ".options!/1" do
    test "with a module not using Knigge" do
      assert_raise ArgumentError,
                   "expected a module using Knigge but DoesNotExist does not.",
                   fn ->
                     Knigge.options!(DoesNotExist)
                   end
    end

    test "with a module using Knigge" do
      defmodule MyModuleUsingKnigge do
        use Knigge, implementation: Something

        @callback my_function() :: no_return
      end

      assert %Knigge.Options{
               behaviour: MyModuleUsingKnigge,
               implementation: Something
             } = Knigge.options!(MyModuleUsingKnigge)
    end

    test "with a module using Knigge being open" do
      defmodule MyOpenModuleUsingKnigge do
        use Knigge, implementation: Something

        @callback my_function() :: no_return

        # We need to invoke `assert` in the module top level to test what happens
        # when the module is still open (being defined)
        assert %Knigge.Options{
                 behaviour: __MODULE__,
                 implementation: Something
               } = Knigge.options!(__MODULE__)
      end
    end
  end
end
