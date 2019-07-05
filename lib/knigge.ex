defmodule Knigge do
  @type key :: :behaviour | :implementation

  defmacro __using__(opts) do
    Knigge.Options.validate!(opts)

    quote do
      Module.register_attribute(__MODULE__, :__knigge__, accumulate: true)

      use Knigge.Behaviour, unquote(opts)
      use Knigge.Implementation, unquote(opts)
      use Knigge.Delegation, unquote(opts)

      @doc "Access Knigge internal values, such as the implementation being delegated to etc."
      @spec __knigge__(:behaviour) :: module()
      @spec __knigge__(:implementation) :: module()
      def __knigge__(key), do: Keyword.fetch!(@__knigge__, key)
    end
  end

  @doc "Access Knigge internal values, such as the implementation being delegated to etc."
  @spec fetch!(module(), :behaviour) :: module()
  @spec fetch!(module(), :implementation) :: module()
  def fetch!(module, key) do
    if function_exported?(module, :__knigge__, 1) do
      module.__knigge__(key)
    else
      raise ArgumentError, "expected a module using Knigge but #{inspect(module)} does not."
    end
  end

  @spec implementation_for(otp_app :: atom(), behaviour :: module()) :: module() | nil
  defdelegate implementation_for(otp_app, behaviour), to: Knigge.Implementation

  @spec implementation_for!(otp_app :: atom(), behaviour :: module()) :: module()
  defdelegate implementation_for!(otp_app, behaviour), to: Knigge.Implementation
end
