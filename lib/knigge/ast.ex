defmodule Knigge.AST do
  @moduledoc false

  def function_spec_from_callback({:callback, spec, _module}) do
    function_spec_from_callback(spec)
  end

  def function_spec_from_callback({:when, _meta, [spec | _]}) do
    function_spec_from_callback(spec)
  end

  def function_spec_from_callback({:"::", _meta, [{name, _, nil}, _return]}) do
    {name, 0}
  end

  def function_spec_from_callback({:"::", _meta, [{name, _, typespeced_args}, _return]}) do
    {name, length(typespeced_args)}
  end
end
