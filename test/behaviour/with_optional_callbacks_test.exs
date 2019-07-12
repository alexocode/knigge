defmodule Behaviour.WithOptionalCallbacksTest do
  use ExUnit.Case, async: true

  import Knigge.Test.SaltedModule

  require Mox

  defmacrop define_facade(do: block) do
    quote do
      implementation = salt_atom(Implementation)

      behaviour =
        defmodule_salted Behaviour do
          use Knigge, implementation: implementation

          @callback my_required_function() :: no_return
          @callback my_optional_function() :: no_return
          @callback my_optional_function_with_arguments(any(), any()) :: no_return

          @optional_callbacks my_optional_function: 0, my_optional_function_with_arguments: 2

          unquote(block)
        end

      %{facade: behaviour, behaviour: behaviour, implementation: implementation}
    end
  end

  defp define_facade, do: define_facade(do: :ok)

  test "does generate delegation for optional callbacks" do
    %{behaviour: behaviour, facade: facade, implementation: implementation} = define_facade()

    Mox.defmock(implementation, for: behaviour)
    Mox.expect(implementation, :my_optional_function, fn -> :ok end)

    facade.my_optional_function()

    Mox.verify!(implementation)
  end

  test "does raise an UndefinedFunctionError when the implementation does not implement the optional callback" do
    %{behaviour: behaviour, facade: facade, implementation: implementation} = define_facade()

    Mox.defmock(implementation, for: behaviour, skip_optional_callbacks: [my_optional_function: 0])

    assert_raise UndefinedFunctionError,
                 "function #{inspect(implementation)}.my_optional_function/0 is undefined or private",
                 fn -> facade.my_optional_function() end
  end

  test "raises a CompileError when a default is being defined for a required callback" do
    assert_raise CompileError,
                 ~r/you can not define a default implementation for a non-optional callback, as it will never be invoked\./,
                 fn ->
                   define_facade do
                     defdefault(my_required_function, do: :this_should_raise)
                   end
                 end
  end

  test "invokes the default when the implementation does not implement the optional callback" do
    %{facade: facade} =
      define_facade do
        defdefault my_optional_function do
          send self(), {__MODULE__, :fallback_invoked, []}

          :my_great_fallback
        end

        defdefault my_optional_function_with_arguments(arg1, arg2) do
          send self(), {__MODULE__, :fallback_with_arguments_invoked, [arg1, arg2]}

          :my_great_fallback_with_arguments
        end
      end

    assert :my_great_fallback == facade.my_optional_function()
    assert_receive {^facade, :fallback_invoked, []}

    assert :my_great_fallback_with_arguments ==
             facade.my_optional_function_with_arguments(42, 1337)

    assert_receive {^facade, :fallback_with_arguments_invoked, [42, 1337]}
  end

  test "does not invoke the default when the implementation actually implements the optional callback" do
    %{behaviour: behaviour, facade: facade, implementation: implementation} =
      define_facade do
        defdefault my_optional_function do
          send self(), {__MODULE__, :fallback_invoked, []}

          :my_great_fallback
        end

        defdefault my_optional_function_with_arguments(arg1, arg2) do
          send self(), {__MODULE__, :fallback_with_arguments_invoked, [arg1, arg2]}

          :my_great_fallback_with_arguments
        end
      end

    Mox.defmock(implementation,
      for: behaviour,
      skip_optional_callbacks: [my_optional_function_with_arguments: 2]
    )

    Mox.expect(implementation, :my_optional_function, fn -> :my_great_implementation end)

    assert :my_great_implementation == facade.my_optional_function()
    refute_receive {^facade, :fallback_invoked, []}

    Mox.verify!(implementation)

    assert :my_great_fallback_with_arguments ==
             facade.my_optional_function_with_arguments(42, 1337)

    assert_receive {^facade, :fallback_with_arguments_invoked, [42, 1337]}
  end
end
