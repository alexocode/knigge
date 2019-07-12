defmodule Knigge.Warnings do
  @moduledoc false

  require Logger

  def definition_matching_callback(module, {name, arity}) do
    Logger.warn(fn ->
      function = "#{name}/#{arity}"

      """
      Knigge encountered definition `#{module}.#{function}` which matches callback `#{function}`.

      It will not delegate this callback! If this is your intention you can tell Knigge to ignore this callback:

          use Knigge, do_not_delegate: [#{name}: #{arity}]
      """
    end)
  end
end
