defmodule KniggeTest do
  use ExUnit.Case, async: true

  import Mox

  describe "SomeBehaviour using Knigge" do
    defmodule SomeBehaviour do
      use Knigge, implementation: SomeBehaviourMock

      @callback my_function(argument :: any()) :: any()
      @callback another_function(list()) :: list()
    end

    defmock SomeBehaviourMock, for: SomeBehaviour

    test "calling my_function/1 delegates the call to SomeBehaviourMock" do
      expect(SomeBehaviourMock, :my_function, fn arg -> send self(), {:argument, arg} end)

      SomeBehaviour.my_function("with some argument")

      assert_receive {:argument, "with some argument"}

      verify!(SomeBehaviourMock)
    end

    test "calling another_function/1 delegates the call to SomeBehaviourMock" do
      expect(SomeBehaviourMock, :another_function, fn arg -> send self(), {:argument, arg} end)

      SomeBehaviour.another_function([1, 2, 3, 4])

      assert_receive {:argument, [1, 2, 3, 4]}

      verify!(SomeBehaviourMock)
    end
  end
end
