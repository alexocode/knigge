defmodule Knigge do
  defmacro __using__(opts) do
    quote do
      use Knigge.Generator, unquote(opts)
    end
  end
end
