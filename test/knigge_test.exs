defmodule KniggeTest do
  use ExUnit.Case, async: true

  import Mox

  describe "a behaviour using Knigge with the direct :implementation option" do
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

    test "defines a __knigge__(:implementation) function" do
      assert SomeBehaviour.__knigge__(:implementation) == SomeBehaviourMock
    end
  end

  describe "a behaviour using Knigge with the :otp_app key" do
    test "raises an ArgumentError without a relevant configuration available" do
      assert_raise ArgumentError,
                   ~r/could not fetch application environment KniggeTest.RaisingBehaviour for application :missing/,
                   fn ->
                     defmodule RaisingBehaviour do
                       use Knigge, otp_app: :missing
                     end
                   end
    end

    test "works fine with the relevant configuration being set in the Application environment" do
      Application.put_env(:knigge, __MODULE__.WorkingBehaviour, SomeModule)

      # Should not raise
      defmodule WorkingBehaviour do
        use Knigge, otp_app: :knigge
      end

      assert WorkingBehaviour.__knigge__(:implementation) == SomeModule
    end
  end

  describe "a behaviour using Knigge without the :implementation and no :otp_app key" do
    test "raises an ArgumentError with a descriptive error" do
      assert_raise ArgumentError,
                   "Knigge expects either an :implementation or :otp_app key but neither was given.",
                   fn ->
                     defmodule AnotherBehaviour do
                       use Knigge
                     end
                   end
    end
  end
end
