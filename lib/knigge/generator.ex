# TODO: Rename to be more KNIGGE
defmodule Knigge.Generator do
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
