defmodule Knigge.Test.SaltedModule do
  @moduledoc false

  @salt 1_000_000_000

  defmacro defmodule_salted(name, do: block) do
    quote do
      name = salt_atom(unquote(name))

      defmodule name do
        unquote(block)
      end

      name
    end
  end

  def salt_atom(name), do: :"#{name}_#{:rand.uniform(@salt)}"
end
