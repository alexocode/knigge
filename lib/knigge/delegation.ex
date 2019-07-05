defmodule Knigge.Delegation do
  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(%{module: module}) do
    delegate = get_delegate(module)
    _definitions = get_definitions(module)

    module
    |> Module.get_attribute(:callback)
    |> Enum.map(fn callback ->
      callback_to_defdelegate(callback, from: module, to: delegate)
    end)
  end

  defp get_delegate(module) do
    module
    |> Module.get_attribute(:__knigge__)
    |> Keyword.fetch!(:implementation)
  end

  defp get_definitions(module) do
    module
    |> Module.definitions_in()
    |> Map.new()
  end

  def callback_to_defdelegate(callback, from: module, to: delegate) do
    {name, arity} = Knigge.AST.function_spec_from_callback(callback)
    args = Macro.generate_arguments(arity, module)

    quote do
      defdelegate unquote(name)(unquote_splicing(args)), to: unquote(delegate)
    end
  end

  def callback_to_defdelegate(callback) do
    raise ArgumentError, "do not know how to handle callback: #{inspect(callback)}"
  end
end
