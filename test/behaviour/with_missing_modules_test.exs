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
                 ~r"the given module could not be found: DoesNotExist",
                 fn ->
                   define_facade(
                     behaviour: Behaviour,
                     implementation: DoesNotExist,
                     check_if_exists?: :test
                   )
                 end
  end

  test "raises a CompileError when the Behaviour does not exist" do
    assert_raise CompileError,
                 ~r"the given module could not be found: MissingBehaviour",
                 fn ->
                   define_facade(
                     behaviour: MissingBehaviour,
                     implementation: Implementation,
                     check_if_exists?: [except: :dev]
                   )
                 end
  end

  test "raises a CompileError when both don't exist and `only: [:test, :dev]` is passed for existence check" do
    assert_raise CompileError,
                 ~r"the given module could not be found: DoesNotExist",
                 fn ->
                   define_facade(
                     behaviour: Behaviour,
                     implementation: DoesNotExist,
                     check_if_exists?: [only: [:test, :dev]]
                   )
                 end
  end

  test "does not raise any error when both the Behaviour and the Implementation exist" do
    define_facade(behaviour: Behaviour, implementation: Implementation)
  end

  test "does not raise any error when the implementation is missing but check_if_exists is set to false" do
    define_facade(
      behaviour: Behaviour,
      implementation: MissingImplementation,
      check_if_exists?: false
    )
  end

  defp define_facade(opts) do
    defmodule_salted Facade do
      use Knigge, opts
    end
  end
end
