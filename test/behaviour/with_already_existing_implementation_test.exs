defmodule Behaviour.WithAlreadyExistingImplementationTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO
  import Knigge.Test.SaltedModule

  require Mox

  defmacrop define_facade(knigge_options \\ []) do
    behaviour = salt_atom(Behaviour)
    implementation = salt_atom(Implementation)
    options = Keyword.put(knigge_options, :implementation, implementation)

    quote bind_quoted: [behaviour: behaviour, implementation: implementation], unquote: true do
      warnings =
        capture_io(:stderr, fn ->
          defmodule behaviour do
            use Knigge, unquote(options)

            @callback my_function_with_default() :: :ok
            @callback my_other_function() :: :ok

            def my_function_with_default, do: :ok
          end
        end)

      Mox.defmock(implementation, for: behaviour)

      %{
        facade: behaviour,
        behaviour: behaviour,
        implementation: implementation,
        warnings: warnings
      }
    end
  end

  test "does not generate a compilation warning for a clause never matching" do
    %{warnings: warnings} = define_facade()

    refute warnings =~
             ~r"this clause cannot match because a previous clause at line \d+ always matches"
  end

  test "prints a Knigge warning for an already existing clause because Knigge doesn't know what to do about it" do
    %{facade: facade, warnings: warnings} = define_facade()

    assert warnings =~ """
           Knigge encountered definition `#{facade}.my_function_with_default/0` which matches callback `my_function_with_default/0`. It will not delegate this callback!
                    If this is your intention you can tell Knigge to ignore this callback:
                      use Knigge, do_not_delegate: [my_function_with_default: 0]
           """
  end

  test "does not print a Knigge warning for an already existing clause when `do_not_delegate` is provided for the definition" do
    %{warnings: warnings} = define_facade(do_not_delegate: [my_function_with_default: 0])

    assert warnings == ""
  end

  test "does not print a Knigge warning for an already existing clause when `warn` is `false`" do
    %{warnings: warnings} = define_facade(warn: false)

    assert warnings == ""
  end
end
