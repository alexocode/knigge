defmodule Knigge.Module do
  @moduledoc false

  def exists?(module, opts) do
    not Knigge.Options.check_if_exists?(opts) or do_exists?(module)
  end

  defp do_exists?(module) do
    Code.ensure_loaded?(module) or Module.open?(module)
  end
end
