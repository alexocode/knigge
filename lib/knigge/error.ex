defmodule Knigge.Error do
  @moduledoc false

  def default_for_required_callback!(env) do
    raise CompileError,
      description:
        "you can not define a default implementation for a required callback, as it will never be invoked.",
      file: env.file,
      line: env.line
  end
end
