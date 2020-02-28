defmodule Knigge.Module do
  @moduledoc false

  alias Knigge.Options

  module = inspect(__MODULE__)

  def ensure_exists!(module, opts, env) do
    unless Knigge.Module.exists?(module, opts) do
      Knigge.Error.module_not_loaded!(module, env)
    end

    module
  end

  @doc """
  Returns true if a module exists, false otherwise. Always returns true if
  `check_if_exists?` is set to `false` on the `Knigge.Options` struct.

  ## Examples

    iex> options = %Knigge.Options{check_if_exists?: true}
    iex> #{module}.exists?(This.Does.Not.Exist, options)
    false

    iex> options = %Knigge.Options{check_if_exists?: false}
    iex> #{module}.exists?(This.Does.Not.Exist, options)
    true

    iex> options = %Knigge.Options{check_if_exists?: true}
    iex> #{module}.exists?(Knigge, options)
    true

    iex> options = %Knigge.Options{check_if_exists?: false}
    iex> #{module}.exists?(Knigge, options)
    true
  """
  @spec exists?(module :: module()) :: boolean()
  def exists?(module, %Options{} = opts) do
    if opts.check_if_exists? do
      exists?(module)
    else
      true
    end
  end

  @doc """
  Returns true if a module exists, false otherwise.

  ## Examples

      iex> #{module}.exists?(This.Does.Not.Exist)
      false

      iex> #{module}.exists?(Knigge)
      true
  """
  @spec exists?(module :: module()) :: boolean()
  def exists?(module) do
    Module.open?(module) or Code.ensure_loaded?(module)
  end
end
