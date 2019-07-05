defmodule Knigge do
  @type key :: :behaviour | :implementation | :opts

  defmacro __using__(opts) do
    Knigge.Options.validate!(opts)

    quote do
      @before_compile Knigge.Delegation

      @__knigge__ [
        opts: unquote(opts),
        behaviour: Knigge.Behaviour.fetch!(__MODULE__, unquote(opts)),
        implementation: Knigge.Implementation.fetch!(__MODULE__, unquote(opts))
      ]

      @doc "Access Knigge internal values, such as the implementation being delegated to etc."
      @spec __knigge__(:behaviour) :: module()
      @spec __knigge__(:implementation) :: module()
      @spec __knigge__(:opts) :: Knigge.Options.t()
      def __knigge__(key), do: Keyword.fetch!(@__knigge__, key)
    end
  end

  @doc "Access Knigge internal values, such as the implementation being delegated to etc."
  @spec fetch!(module(), :behaviour) :: module()
  @spec fetch!(module(), :implementation) :: module()
  @spec fetch!(module(), :opts) :: Knigge.Options.t()
  def fetch!(module, key) do
    cond do
      Module.open?(module) ->
        module
        |> Module.get_attribute(:__knigge__)
        |> Keyword.fetch!(key)

      function_exported?(module, :__knigge__, 1) ->
        module.__knigge__(key)

      true ->
        raise ArgumentError, "expected a module using Knigge but #{inspect(module)} does not."
    end
  end
end
