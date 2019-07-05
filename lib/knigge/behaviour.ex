defmodule Knigge.Behaviour do
  def fetch!(module, opts) do
    Keyword.get(opts, :behaviour, module)
  end

  def callbacks(module) do
    if Module.open?(module) do
      callbacks_from_attribute(module)
    else
      module.behaviour_info(:callbacks)
    end
  end

  defp callbacks_from_attribute(module) do
    module
    |> Module.get_attribute(:callback)
    |> Enum.map(&Knigge.AST.function_spec_from_callback/1)
  end
end
