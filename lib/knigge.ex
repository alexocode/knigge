defmodule Knigge do
  defmacro __using__(opts) do
    Knigge.Options.validate!(opts)

    quote do
      Module.register_attribute(__MODULE__, :__knigge__, accumulate: true)

      use Knigge.Implementation, unquote(opts)
      use Knigge.Delegation, unquote(opts)

      def __knigge__(key), do: Keyword.fetch!(@__knigge__, key)
    end
  end

  @spec implementation_for(otp_app :: atom(), behaviour :: module()) :: module() | nil
  defdelegate implementation_for(otp_app, behaviour), to: Knigge.Implementation

  @spec implementation_for!(otp_app :: atom(), behaviour :: module()) :: module()
  defdelegate implementation_for!(otp_app, behaviour), to: Knigge.Implementation
end
