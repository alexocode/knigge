defmodule Knigge.Implementation do
  defmacro __using__(opts) do
    implementation = Keyword.get(opts, :implementation)
    otp_app = Keyword.get(opts, :otp_app)

    quote do
      if unquote(implementation) do
        @__knigge__ {:implementation, unquote(implementation)}
      else
        @__knigge__ {
          :implementation,
          unquote(__MODULE__).implementation_for!(unquote(otp_app), __MODULE__)
        }
      end
    end
  end

  def implementation_for(app, behaviour), do: Application.get_env(app, behaviour)
  def implementation_for!(app, behaviour), do: Application.fetch_env!(app, behaviour)
end
