defmodule Knigge.Test.SaltedModule do
  @moduledoc false

  @salt 1_000_000_000

  defmacro defmodule_salted(name, do: block) do
    quote bind_quoted: [name: name], unquote: true do
      name = salt_atom(name)

      defmodule name do
        unquote(block)
      end

      name
    end
  end

  defmacro defmock_salted(name, opts) do
    quote bind_quoted: [name: name, opts: opts] do
      name = salt_atom(name)

      require Mox

      Mox.defmock(name, opts)

      name
    end
  end

  def salt_atom(name), do: :"#{name}_#{:rand.uniform(@salt)}"
end
