defmodule Knigge.Warnings do
  @moduledoc false

  require Logger

  defmacrop warn(module, message) do
    quote do
      unquote(module)
      |> Knigge.fetch!(:options)
      |> Keyword.get(:warn, true)
      |> if do
        Logger.warn(unquote(message))
      end
    end
  end

  def definition_matching_callback(module, {name, arity}) do
    warn(module, fn ->
      function = "#{name}/#{arity}"

      """
      Knigge encountered definition `#{module}.#{function}` which matches callback `#{function}`.

      It will not delegate this callback! If this is your intention you can tell Knigge to ignore this callback:

          use Knigge, do_not_delegate: [#{name}: #{arity}]
      """
    end)
  end
end
