defmodule Behaviour.WithDefdefaultForOpenModuleTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
  import Knigge.Test.SaltedModule

  defmacrop define_facade(knigge_options \\ []) do
    implementation = salt_atom(Implementation)
    behaviour = Module.concat([implementation, Behaviour])

    options = Keyword.put(knigge_options, :implementation, implementation)

    quote bind_quoted: [behaviour: behaviour, implementation: implementation], unquote: true do
      warnings =
        capture_io(:stderr, fn ->
          defmodule implementation do
            defmodule Behaviour do
              use Knigge, unquote(options)

              @callback my_function_with_default() :: atom()
              @optional_callbacks my_function_with_default: 0

              defdefault my_function_with_default, do: :default
            end

            @behaviour Behaviour

            @impl Behaviour
            def my_function_with_default, do: :impl
          end
        end)

      %{
        facade: behaviour,
        behaviour: behaviour,
        implementation: implementation,
        warnings: warnings
      }
    end
  end

  test "prints a warning that the implementation check for defdefault can only be resolved at runtime" do
    %{
      facade: facade,
      implementation: implementation,
      warnings: warnings
    } = define_facade()

    assert_lines(
      warnings,
      """
      Knigge encountered a `defdefault` while the implementation `#{inspect(implementation)}` was still being compiled.
      This means Knigge can not determine whether it implements `my_function_with_default/0` at compile time but needs to fallback to a runtime check.

      There are two ways to resolve this warning:
        1. move the behaviour into a separate module and `use Knigge, behaviour: MyBehaviour`;
           this enables to compiler to finish compilation of `#{inspect(implementation)}` before compiling `#{inspect(facade)}`
        2. pass `delegate_at_runtime?: true` as option, this will move **all** delegation to runtime
      """
    )
  end

  test "does not print a warning when `delegate_at_runtime?: true` is passed" do
    %{warnings: warnings} = define_facade(delegate_at_runtime?: true)

    assert warnings == ""
  end

  defp assert_lines(received, expected) do
    [
      String.split(received, "\n"),
      String.split(expected, "\n")
    ]
    |> Enum.zip()
    |> Enum.each(fn {received, expected} ->
      assert received =~ expected
    end)
  end
end
