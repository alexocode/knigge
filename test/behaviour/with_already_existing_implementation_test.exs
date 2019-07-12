defmodule Behaviour.WithAlreadyExistingImplementationTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog
  import ExUnit.CaptureIO

  require Mox

  defmacrop define_knigge_facade do
    salt = :random.uniform(100_000)
    behaviour = String.to_atom("MyBehaviourWithDefaults#{salt}")
    implementation = String.to_atom("MyImplementation#{salt}")

    quote bind_quoted: [behaviour: behaviour, implementation: implementation] do
      logs =
        capture_log(fn ->
          warnings =
            capture_io(:stderr, fn ->
              defmodule behaviour do
                use Knigge, implementation: implementation

                @callback my_function_with_default() :: :ok
                @callback my_other_function() :: :ok

                def my_function_with_default, do: :ok
              end
            end)

          send self(), {:warnings, warnings}
        end)

      warnings =
        receive do
          {:warnings, warnings} -> warnings
        end

      Mox.defmock(implementation, for: behaviour)

      %{
        facade: behaviour,
        behaviour: behaviour,
        implementation: implementation,
        logs: logs,
        warnings: warnings
      }
    end
  end

  test "calling `my_function/0` does not invoke the implementation's version" do
    %{facade: facade, implementation: implementation} = define_knigge_facade()

    Mox.stub(implementation, :my_function_with_default, fn ->
      send self(), {implementation, :my_function_with_default, []}

      :ok
    end)

    Mox.stub(implementation, :my_other_function, fn ->
      send self(), {implementation, :my_other_function, []}

      :ok
    end)

    assert :ok = facade.my_other_function()
    assert :ok = facade.my_function_with_default()

    assert_receive {^implementation, :my_other_function, []}
    refute_receive {^implementation, :my_function_with_default, []}
  end

  test "does not generate a compilation warning for a clause never matching" do
    %{warnings: warnings} = define_knigge_facade()

    refute warnings =~
             ~r"this clause cannot match because a previous clause at line \d+ always matches"
  end

  test "logs a Knigge warning for an already existing clause because Knigge doesn't know what to do about it" do
    %{facade: facade, logs: logs} = define_knigge_facade()

    assert logs =~ """
           Knigge encountered definition `#{facade}.my_function_with_default/0` which matches callback `my_function_with_default/0`.

           It will not delegate this callback! If this is your intention you can tell Knigge to ignore this callback:

               use Knigge, do_not_delegate: [my_function_with_default: 0]
           """
  end
end
