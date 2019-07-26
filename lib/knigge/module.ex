defmodule Knigge.Module do
  @moduledoc false

  alias Knigge.Options

  def ensure_exists!(module, opts, env) do
    unless Knigge.Module.exists?(module, opts) do
      Knigge.Error.module_not_loaded!(module, env)
    end

    module
  end

  def exists?(_module, %Options{check_if_exists?: false}), do: true

  def exists?(module, %Options{check_if_exists?: true}) do
    Code.ensure_loaded?(module) or Module.open?(module)
  end
end
