defmodule Knigge.Delegation do
  alias Knigge.Warnings, as: Warn

  defmacro __before_compile__(%{module: module}) do
    generate(module)
  end

  def generate(module) do
    delegate = get_delegate(module)
    definitions = get_definitions(module)

    module
    |> Knigge.Behaviour.callbacks()
    |> Enum.map(fn callback ->
      if callback in definitions do
        Warn.definition_matching_callback(module, callback)
      else
        callback_to_defdelegate(callback, from: module, to: delegate)
      end
    end)
  end

  defp get_delegate(module) do
    module
    |> Module.get_attribute(:__knigge__)
    |> Keyword.fetch!(:implementation)
  end

  defp get_definitions(module) do
    Module.definitions_in(module)
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
