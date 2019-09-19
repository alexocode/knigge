defmodule Knigge.Code.Delegate do
  @moduledoc false

  alias Knigge.Implementation

  def callback_to_defdelegate({name, arity}, from: module, delegate_at_runtime?: false, env: env) do
    callback_to_defdelegate({name, arity},
      from: module,
      to: Implementation.fetch_for!(module, env)
    )
  end

  def callback_to_defdelegate({name, arity}, from: _module, delegate_at_runtime?: true, env: _env) do
    quote bind_quoted: [name: name, arity: arity] do
      args = Macro.generate_arguments(arity, __MODULE__)

      def unquote(name)(unquote_splicing(args)) do
        apply(__knigge__(:implementation), unquote(name), unquote(args))
      end
    end
  end

  def callback_to_defdelegate({name, arity}, from: _module, to: implementation) do
    quote bind_quoted: [name: name, arity: arity, implementation: implementation] do
      args = Macro.generate_arguments(arity, __MODULE__)

      defdelegate unquote(name)(unquote_splicing(args)), to: implementation
    end
  end
end
