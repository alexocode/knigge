defmodule Knigge.Delegation do
  defmacro __before_compile__(%{module: module}) do
    generate(module)
  end

  def generate(module) do
    delegate = get_delegate(module)
    _definitions = get_definitions(module)

    module
    |> Knigge.Behaviour.callbacks()
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

  def callback_to_defdelegate({name, arity}, from: module, to: delegate) do
    args = Macro.generate_arguments(arity, module)

    quote do
      defdelegate unquote(name)(unquote_splicing(args)), to: unquote(delegate)
    end
  end

  def callback_to_defdelegate(callback) do
    raise ArgumentError, "do not know how to handle callback: #{inspect(callback)}"
  end
end
