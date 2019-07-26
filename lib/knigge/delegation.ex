defmodule Knigge.Delegation do
  alias Knigge.Error
  alias Knigge.Warnings, as: Warn

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__), only: [defdefault: 2]

      @before_compile unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :__knigge_defaults__, accumulate: true)
    end
  end

  defmacro defdefault({_name, _meta, _args} = definition, do: block) do
    do_defdefault(definition, do: block)
  end

  defp do_defdefault({name, _meta, args}, do: block) when is_list(args) do
    key = {name, length(args)}
    value = {Macro.escape(args), Macro.escape(block)}

    quote do
      @__knigge_defaults__ {unquote(key), unquote(value)}
    end
  end

  # The `args` are not a list for definitions like `defdefault my_default, do: :ok`
  # where no parenthesis follow after `my_default`
  defp do_defdefault({name, meta, _args}, do: block) do
    do_defdefault({name, meta, []}, do: block)
  end

  defmacro __before_compile__(%{module: module} = env) do
    generate(module, env)
  end

  def generate(module, env) do
    behaviour = Knigge.fetch!(module, :behaviour)
    callbacks = get_callbacks(behaviour)
    optional_callbacks = get_optional_callbacks(behaviour)
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
          unless callback in optional_callbacks do
            Error.default_for_required_callback!(env)
          end

          callback_to_defdefault(callback, to: implementation, default: defaults[callback])

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
    cond do
      Module.open?(implementation) ->
        # The module is being compiled, we need to determine at runtime if delegation can happen
        quote do
          def unquote(name)(unquote_splicing(args)) do
            if function_exported?(unquote(implementation), unquote(name), unquote(arity)) do
              apply(unquote(implementation), unquote(name), unquote(args))
            else
              unquote(block)
            end
          end
        end

      function_exported?(implementation, name, arity) ->
        # The module is compiled and the function exists, we can simply delegate
        callback_to_defdelegate({name, arity}, to: implementation)

      true ->
        # The module is compiled and the function is missing, we can use the default
        quote do
          def unquote(name)(unquote_splicing(args)) do
            unquote(block)
          end
        end
    end
  end

  defp callback_to_defdelegate({name, _arity}, arguments: args, to: implementation) do
    quote bind_quoted: [name: name, args: args, implementation: implementation] do
      defdelegate unquote(name)(unquote_splicing(args)), to: implementation
    end
  end

  defp callback_to_defdelegate({name, arity}, to: implementation) do
    quote bind_quoted: [name: name, arity: arity, implementation: implementation] do
      args = Macro.generate_arguments(arity, __MODULE__)

      defdelegate unquote(name)(unquote_splicing(args)), to: implementation
    end
  end
end
