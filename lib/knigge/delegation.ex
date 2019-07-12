defmodule Knigge.Delegation do
  alias Knigge.Warnings, as: Warn

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__), only: [defdefault: 2]

      @before_compile unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :__knigge_defaults__, accumulate: true)
    end
  end

  defmacro defdefault({name, _meta, args}, do: block) do
    args = args || []
    key = {name, length(args)}
    value = {Macro.escape(args), Macro.escape(block)}

    quote do
      @__knigge_defaults__ {unquote(key), unquote(value)}
    end
  end

  defmacro __before_compile__(%{module: module}) do
    generate(module)
  end

  def generate(module) do
    callbacks = get_callbacks(module)
    _optional_callbacks = get_optional_callbacks(module)
    do_not_delegate = get_do_not_delegate_option(module)
    definitions = get_definitions(module)
    implementation = get_implementation(module)
    defaults = get_defaults(module)

    for callback <- callbacks do
      cond do
        callback in do_not_delegate ->
          :ok

        callback in definitions ->
          Warn.definition_matching_callback(module, callback)

        Map.has_key?(defaults, callback) ->
          # unless callback in optional_callbacks do
          #   raise ArgumentError
          # end

          default = Map.get(defaults, callback)

          callback_to_defdefault(callback, to: implementation, default: default)

        true ->
          callback_to_defdelegate(callback, to: implementation)
      end
    end
  end

  defp get_callbacks(module) do
    Knigge.Behaviour.callbacks(module)
  end

  defp get_optional_callbacks(module) do
    Knigge.Behaviour.optional_callbacks(module)
  end

  defp get_do_not_delegate_option(module) do
    module
    |> Knigge.fetch!(:options)
    |> Keyword.get(:do_not_delegate, [])
  end

  defp get_implementation(module) do
    Knigge.fetch!(module, :implementation)
  end

  defp get_definitions(module) do
    Module.definitions_in(module)
  end

  defp get_defaults(module) do
    module
    |> Module.get_attribute(:__knigge_defaults__)
    |> Map.new()
  end

  defp callback_to_defdefault(
         {name, arity},
         to: implementation,
         default: {args, block}
       ) do
    quote do
      def unquote(name)(unquote_splicing(args)) do
        if function_exported?(unquote(implementation), unquote(name), unquote(arity)) do
          apply(unquote(implementation), unquote(name), unquote(args))
        else
          unquote(block)
        end
      end
    end
  end

  defp callback_to_defdelegate({name, arity}, to: implementation) do
    quote bind_quoted: [name: name, arity: arity, implementation: implementation] do
      args = Macro.generate_arguments(arity, __MODULE__)

      defdelegate unquote(name)(unquote_splicing(args)), to: implementation
    end
  end
end
