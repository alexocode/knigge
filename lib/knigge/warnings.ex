defmodule Knigge.Warnings do
  @moduledoc false

  require Logger

  defmacrop warn(module, message) do
    quote do
      unquote(module)
      |> Knigge.options!()
      |> Map.get(:warn)
      |> if do
        unquote(message)
        |> Knigge.Warnings.sanitze()
        |> IO.warn(Macro.Env.stacktrace(__ENV__))
      end
    end
  end

  def defdefault_for_open_implementation(
        module,
        implementation: implementation,
        function: {name, arity}
      ) do
    warn(module, """
    Knigge encountered a `defdefault` while the implementation `#{inspect(implementation)}` was still being compiled.
    This means Knigge can not determine whether it implements `#{name}/#{arity}` at compile time but needs to fallback to a runtime check.

    There are two ways to resolve this warning:
      1. move the behaviour into a separate module and `use Knigge, behaviour: MyBehaviour`;
         this enables to compiler to finish compilation of `#{inspect(implementation)}` before compiling `#{inspect(module)}`
      2. pass `delegate_at_runtime?: true` as option, this will move **all** delegation to runtime
    """)
  end

  def definition_matching_callback(module, {name, arity}) do
    function = "#{name}/#{arity}"

    warn(module, """
    Knigge encountered definition `#{module}.#{function}` which matches callback `#{function}`. It will not delegate this callback!
    If this is your intention you can tell Knigge to ignore this callback:
      use Knigge, do_not_delegate: [#{name}: #{arity}]
    """)
  end

  def sanitze(message) do
    message
    |> String.split("\n")
    # Indent by 9 spaces to line them up with the "warning: " label
    |> Enum.join("\n         ")
  end
end
