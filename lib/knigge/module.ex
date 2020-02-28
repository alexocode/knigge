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

  @doc """
  Returns all modules which `use Knigge` for the given app. If the app does not
  exist an error is returned. To determine if `Knigge` is `use`d we check if the
  module exports the `__knigge__/0` function which acts as a "tag".

  `fetch_for_app/1` makes use of `Code.ensure_loaded?/1` to force the module
  being loaded. Since this results in a `GenServer.call/3` to the code server
  __do not use this__ in a hot code path, as it __will__ result in a slowdown!

  ## Examples

      iex> #{module}.fetch_for_app(:this_does_not_exist)
      {:error, :undefined}

      iex> #{module}.fetch_for_app(:knigge)
      {:ok, []}
  """
  @spec fetch_for_app(app :: atom()) :: {:ok, list(module())} | {:error, :undefined}
  def fetch_for_app(app) do
    with {:ok, modules} <- :application.get_key(app, :modules) do
      {:ok, Enum.filter(modules, &uses_knigge?/1)}
    else
      :undefined -> {:error, :undefined}
    end
  end

  defp uses_knigge?(module) do
    Code.ensure_loaded?(module) and function_exported?(module, :__knigge__, 0)
  end
end
