defmodule Knigge.Delegation do
  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(%{module: module}) do
    delegate = Module.get_attribute(module, :__knigge__)[:implementation]

    module
    |> Module.get_attribute(:callback)
    |> Enum.map(&callback_to_defdelegate(&1, from: module, to: delegate))
  end

  def callback_to_defdelegate(
        {
          :callback,
          {
            :"::",
            _,
            [{name, _, typespeced_args}, _return]
          },
          _module
        },
        from: module,
        to: delegate
      ) do
    args = Macro.generate_arguments(length(typespeced_args), module)

    quote do
      defdelegate unquote(name)(unquote_splicing(args)), to: unquote(delegate)
    end
  end

  def callback_to_defdelegate(callback) do
    raise ArgumentError, "do not know how to handle callback: #{inspect(callback)}"
  end
end
