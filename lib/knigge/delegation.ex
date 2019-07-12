defmodule Knigge.Delegation do
  alias Knigge.Warnings, as: Warn

  defmacro __before_compile__(%{module: module}) do
    generate(module)
  end

  def generate(module) do
    do_not_delegate = get_do_not_delegate_option(module)
    definitions = get_definitions(module)
    implementation = get_implementation(module)

    module
    |> Knigge.Behaviour.callbacks()
    |> Enum.reject(&(&1 in do_not_delegate))
    |> Enum.map(fn callback ->
      if callback in definitions do
        Warn.definition_matching_callback(module, callback)
      else
        callback_to_defdelegate(callback, from: module, to: implementation)
      end
    end)
  end

  defp get_implementation(module) do
    Knigge.fetch!(module, :implementation)
  end

  defp get_definitions(module) do
    Module.definitions_in(module)
  end

  defp get_do_not_delegate_option(module) do
    module
    |> Knigge.fetch!(:options)
    |> Keyword.get(:do_not_delegate, [])
  end

  def callback_to_defdelegate({name, arity}, from: module, to: implementation) do
    args = Macro.generate_arguments(arity, module)

    quote do
      defdelegate unquote(name)(unquote_splicing(args)), to: unquote(implementation)
    end
  end

  def callback_to_defdelegate(callback) do
    raise ArgumentError, "do not know how to handle callback: #{inspect(callback)}"
  end
end
