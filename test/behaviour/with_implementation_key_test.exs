defmodule Behaviour.WithImplementationKeyTest do
  use ExUnit.Case, async: true

  import Mox

  defmodule SomeBehaviour do
    use Knigge,
      implementation: SomeBehaviourMock,
      check_if_exists?: false

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

  test "defines a __knigge__(:behaviour) function" do
    assert SomeBehaviour.__knigge__(:behaviour) == SomeBehaviour
  end

  test "defines a __knigge__(:implementation) function" do
    assert SomeBehaviour.__knigge__(:implementation) == SomeBehaviourMock
  end
end
