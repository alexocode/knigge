defmodule Knigge do
  @type key :: :implementation

  defmacro __using__(opts) do
    Knigge.Options.validate!(opts)

    quote do
      Module.register_attribute(__MODULE__, :__knigge__, accumulate: true)

      use Knigge.Implementation, unquote(opts)
      use Knigge.Delegation, unquote(opts)

      @doc "Access Knigge internal values, such as the implementation being delegated to etc."
      @spec __knigge__(key :: Knigge.key()) :: any()
      def __knigge__(key), do: Keyword.fetch!(@__knigge__, key)
    end
  end

  @spec implementation_for(otp_app :: atom(), behaviour :: module()) :: module() | nil
  defdelegate implementation_for(otp_app, behaviour), to: Knigge.Implementation

  @spec implementation_for!(otp_app :: atom(), behaviour :: module()) :: module()
  defdelegate implementation_for!(otp_app, behaviour), to: Knigge.Implementation
end
