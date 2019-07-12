defmodule Behaviour.WithMissingModulesTest do
  use ExUnit.Case, async: true

  import Knigge.Test.SaltedModule

  defmodule Behaviour do
    @callback some_function() :: no_return
  end

  defmodule Implementation do
    @behaviour Behaviour

    @impl true
    def some_function, do: nil
  end

  test "raises a CompileError when the Implementation does not exist" do
    assert_raise CompileError,
                 ~r"the implementing module could not be found: DoesNotExist",
                 fn -> define_facade(behaviour: Behaviour, implementation: DoesNotExist) end
  end

  test "raises a CompileError when the Behaviour does not exist" do
    assert_raise CompileError,
                 ~r"the behaviour module could not be found: MissingBehaviour",
                 fn ->
                   define_facade(behaviour: MissingBehaviour, implementation: Implementation)
                 end
  end

  test "does not raise any error when both the Behaviour and the Implementation exist" do
    define_facade(behaviour: Behaviour, implementation: Implementation)
  end

  defp define_facade(opts) do
    defmodule_salted Facade do
      use Knigge, opts
    end
  end
end
