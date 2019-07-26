defmodule Knigge.Delegation do
  @moduledoc """
  Injects the actual delegations to the implementing module. For this it gets
  registered as a `before_compile`-hook from where it fetches all callbacks from
  the behaviour and generates delegating functions for each callback.

  It also defines the `defdefault` macro.
  """

  alias Knigge.Error
  alias Knigge.Warnings, as: Warn

  defmacro defdefault({_name, _meta, _args} = definition, do: block) do
    do_defdefault(definition, do: block)
  end

  defp do_defdefault({name, _meta, args}, do: block) when is_list(args) do
    key = {name, length(args)}
    value = {Macro.escape(args), Macro.escape(block)}

    quote do
      @__knigge__ {:defdefault, {unquote(key), unquote(value)}}
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
    behaviour = get_behaviour(module, env)
    callbacks = get_callbacks(behaviour)
    optional_callbacks = get_optional_callbacks(behaviour)
    delegate_at = get_option(module, :delegate_at)
    do_not_delegate = get_option(module, :do_not_delegate)
    definitions = get_definitions(module)
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

          callback_to_defdefault(callback,
            from: module,
            default: defaults[callback],
            delegate_at: delegate_at,
            env: env
          )

        true ->
          callback_to_defdelegate(callback,
            from: module,
            delegate_at: delegate_at,
            env: env
          )
      end
    end
  end

  defp get_behaviour(module, env) do
    opts = Knigge.options!(module)

    opts
    |> Knigge.Behaviour.fetch!()
    |> Knigge.Module.ensure_exists!(opts, env)
  end

  defp get_callbacks(module) do
    Knigge.Behaviour.callbacks(module)
  end

  defp get_optional_callbacks(module) do
    Knigge.Behaviour.optional_callbacks(module)
  end

  defp get_option(module, key) do
    module
    |> Knigge.options!()
    |> Map.get(key)
  end

  defp get_definitions(module) do
    Module.definitions_in(module)
  end

  defp get_defaults(module) do
    module
    |> Module.get_attribute(:__knigge__)
    |> Keyword.get_values(:defdefault)
    |> Map.new()
  end

  defp callback_to_defdefault(
         {name, arity},
         from: module,
         default: {args, block},
         delegate_at: :compile_time,
         env: env
       ) do
    implementation = fetch_implementation!(module, env)

    cond do
      Module.open?(implementation) ->
        Warn.defdefault_for_open_implementation(module,
          implementation: implementation,
          function: {name, arity}
        )

        # The module is being compiled, we need to determine at runtime if delegation can happen
        callback_to_defdefault(
          {name, arity},
          from: module,
          default: {args, block},
          delegate_at: :runtime,
          env: env
        )

      function_exported?(implementation, name, arity) ->
        # The module is compiled and the function exists, we can simply delegate
        callback_to_defdelegate({name, arity}, from: module, to: implementation)

      true ->
        # The module is compiled and the function is missing, we can use the default
        quote do
          def unquote(name)(unquote_splicing(args)) do
            unquote(block)
          end
        end
    end
  end

  defp callback_to_defdefault(
         {name, arity},
         from: _module,
         default: {args, block},
         delegate_at: :runtime,
         env: _env
       ) do
    quote do
      def unquote(name)(unquote_splicing(args)) do
        implementation = __knigge__(:implementation)

        if function_exported?(implementation, unquote(name), unquote(arity)) do
          apply(implementation, unquote(name), unquote(args))
        else
          unquote(block)
        end
      end
    end
  end

  defp callback_to_defdelegate({name, arity}, from: module, delegate_at: :compile_time, env: env) do
    callback_to_defdelegate({name, arity}, from: module, to: fetch_implementation!(module, env))
  end

  defp callback_to_defdelegate({name, arity}, from: _module, delegate_at: :runtime, env: _env) do
    quote bind_quoted: [name: name, arity: arity] do
      args = Macro.generate_arguments(arity, __MODULE__)

      def unquote(name)(unquote_splicing(args)) do
        apply(__knigge__(:implementation), unquote(name), unquote(args))
      end
    end
  end

  defp callback_to_defdelegate({name, arity}, from: _module, to: implementation) do
    quote bind_quoted: [name: name, arity: arity, implementation: implementation] do
      args = Macro.generate_arguments(arity, __MODULE__)

      defdelegate unquote(name)(unquote_splicing(args)), to: implementation
    end
  end

  defp fetch_implementation!(module, env) do
    opts = Knigge.options!(module)

    opts
    |> Knigge.Implementation.fetch!()
    |> Knigge.Module.ensure_exists!(opts, env)
  end
end
