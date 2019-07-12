defmodule Behaviour.WithAlreadyExistingImplementationTest do
  use ExUnit.Case, async: true

  require Mox

  defmacrop define_behaviour do
    salt = :random.uniform(100_000)
    behaviour = String.to_atom("MyBehaviourWithDefaults#{salt}")
    implementation = String.to_atom("MyImplementation#{salt}")

    quote bind_quoted: [behaviour: behaviour, implementation: implementation] do
      defmodule behaviour do
        use Knigge,
          implementation: implementation

        @callback my_function_with_default() :: :ok
        @callback my_other_function() :: :ok

        def my_function, do: :ok
      end

      Mox.defmock(implementation, for: behaviour)

      %{behaviour: behaviour, implementation: implementation}
    end
  end

  test "calling `my_function/0` does not invoke the implementation's version" do
    %{behaviour: behaviour, implementation: implementation} = define_behaviour()

    Mox.stub(implementation, :my_function_with_default, fn ->
      send self(), {implementation, :my_function_with_default, []}

      :ok
    end)

    Mox.stub(implementation, :my_other_function, fn ->
      send self(), {implementation, :my_other_function, []}

      :ok
    end)

    assert :ok = behaviour.my_other_function()
    assert :ok = behaviour.my_function_with_default()

    assert_receive {^implementation, :my_other_function, []}
    refute_receive {^implementation, :my_function_with_default, []}
  end
end
