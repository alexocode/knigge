defmodule Knigge.Code.Default do
  @moduledoc false

  alias Knigge.Code.Delegate
  alias Knigge.Implementation
  alias Knigge.Warnings, as: Warn

  def callback_to_defdefault(
        {name, arity},
        from: module,
        default: {args, block},
        delegate_at_runtime?: false,
        env: env
      ) do
    implementation = Implementation.fetch_for!(module, env)

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
          delegate_at_runtime?: true,
          env: env
        )

      function_exported?(implementation, name, arity) ->
        # The module is compiled and the function exists, we can simply delegate
        Delegate.callback_to_defdelegate({name, arity}, from: module, to: implementation)

      true ->
        # The module is compiled and the function is missing, we can use the default
        quote do
          def unquote(name)(unquote_splicing(args)) do
            unquote(block)
          end
        end
    end
  end

  def callback_to_defdefault(
        {name, arity},
        from: _module,
        default: {args, block},
        delegate_at_runtime?: true,
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
end
