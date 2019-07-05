defmodule Knigge.AST do
  def function_spec_from_callback({
        :callback,
        {
          :"::",
          _meta,
          [{name, _, typespeced_args}, _return]
        },
        _module
      }) do
    {name, length(typespeced_args)}
  end
end
