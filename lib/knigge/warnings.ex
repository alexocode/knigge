defmodule Knigge.Warnings do
  @moduledoc false

  require Logger

  defmacrop warn(module, message) do
    quote do
      unquote(module)
      |> Knigge.fetch!(:options)
      |> Keyword.get(:warn, true)
      |> if do
        unquote(message)
        |> Knigge.Warnings.sanitze()
        |> IO.warn(Macro.Env.stacktrace(__ENV__))
      end
    end
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
