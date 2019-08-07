defmodule Knigge.Module do
  @moduledoc false

  alias Knigge.Options

  def ensure_exists!(module, opts, env) do
    unless Knigge.Module.exists?(module, opts) do
      Knigge.Error.module_not_loaded!(module, env)
    end

    module
  end

  def exists?(module, opts) do
    if Options.check_if_exists?(opts) do
      Code.ensure_loaded?(module) or Module.open?(module)
    else
      true
    end
  end
end
