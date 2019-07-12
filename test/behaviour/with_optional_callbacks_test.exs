defmodule Behaviour.WithOptionalCallbacksTest do
  use ExUnit.Case, async: true

  import Knigge.Test.SaltedModule

  require Mox

  defmacrop define_facade_with_mock(mox_options, do: block) do
    quote do
      behaviour =
        defmodule_salted Behaviour do
          @callback my_required_function() :: no_return
          @callback my_optional_function() :: no_return
          @callback my_optional_function_with_arguments(any(), any()) :: no_return

          @optional_callbacks my_optional_function: 0, my_optional_function_with_arguments: 2
        end

      implementation = defmock_salted(Implementation, [{:for, behaviour} | unquote(mox_options)])

      facade =
        defmodule_salted Facade do
          use Knigge,
            behaviour: behaviour,
            implementation: implementation

          unquote(block)
        end

      %{facade: facade, behaviour: behaviour, implementation: implementation}
    end
  end

  defp define_facade_with_mock(mox_options \\ []),
    do: define_facade_with_mock(mox_options, do: :ok)

  test "does generate delegation for optional callbacks" do
    %{facade: facade, implementation: implementation} = define_facade_with_mock()

    Mox.expect(implementation, :my_optional_function, fn -> :ok end)

    facade.my_optional_function()

    Mox.verify!(implementation)
  end

  test "does raise an UndefinedFunctionError when the implementation does not implement the optional callback" do
    %{facade: facade, implementation: implementation} =
      define_facade_with_mock(skip_optional_callbacks: [my_optional_function: 0])

    assert_raise UndefinedFunctionError,
                 "function #{inspect(implementation)}.my_optional_function/0 is undefined or private",
                 fn -> facade.my_optional_function() end
  end

  test "raises a CompileError when a default is being defined for a required callback" do
    assert_raise CompileError,
                 ~r/you can not define a default implementation for a required callback, as it will never be invoked\./,
                 fn ->
                   define_facade_with_mock [] do
                     defdefault(my_required_function, do: :this_should_raise)
                   end
                 end
  end

  test "invokes the default when the implementation does not implement the optional callback" do
    %{facade: facade} =
      define_facade_with_mock skip_optional_callbacks: [
                                my_optional_function: 0,
                                my_optional_function_with_arguments: 2
                              ] do
        defdefault my_optional_function do
          send self(), {__MODULE__, :my_optional_function, []}

          :my_great_default
        end

        defdefault my_optional_function_with_arguments(arg1, arg2) do
          send self(), {__MODULE__, :my_optional_function_with_arguments, [arg1, arg2]}

          :my_great_default_with_arguments
        end
      end

    assert :my_great_default == facade.my_optional_function()
    assert_receive {^facade, :my_optional_function, []}

    assert :my_great_default_with_arguments ==
             facade.my_optional_function_with_arguments(42, 1337)

    assert_receive {^facade, :my_optional_function_with_arguments, [42, 1337]}
  end

  test "does not invoke the default when the implementation actually implements the optional callback" do
    %{facade: facade, implementation: implementation} =
      define_facade_with_mock skip_optional_callbacks: [my_optional_function_with_arguments: 2] do
        defdefault my_optional_function do
          send self(), {__MODULE__, :my_optional_function, []}

          :my_great_default
        end

        defdefault my_optional_function_with_arguments(arg1, arg2) do
          send self(), {__MODULE__, :my_optional_function_with_arguments, [arg1, arg2]}

          :my_great_default_with_arguments
        end
      end

    Mox.expect(implementation, :my_optional_function, fn -> :my_great_implementation end)

    assert :my_great_implementation == facade.my_optional_function()
    refute_receive {^facade, :my_optional_function, []}

    Mox.verify!(implementation)

    assert :my_great_default_with_arguments ==
             facade.my_optional_function_with_arguments(42, 1337)

    assert_receive {^facade, :my_optional_function_with_arguments, [42, 1337]}
  end

  test "invokes the default when the behaviour is external from the facade" do
    behaviour =
      defmodule_salted Behaviour do
        @callback my_required_callback() :: no_return
        @callback my_optional_callback() :: no_return

        @optional_callbacks my_optional_callback: 0
      end

    implementation =
      defmock_salted(Implementation,
        for: behaviour,
        skip_optional_callbacks: [my_optional_callback: 0]
      )

    facade =
      defmodule_salted Facade do
        use Knigge,
          behaviour: behaviour,
          implementation: implementation

        defdefault my_optional_callback do
          :my_great_default
        end
      end

    assert :my_great_default == facade.my_optional_callback()

    Mox.expect(implementation, :my_required_callback, fn -> :my_great_implementation end)

    assert :my_great_implementation == facade.my_required_callback()
  end
end
