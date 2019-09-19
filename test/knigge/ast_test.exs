defmodule Knigge.ASTTest.TestModuleWithCallbacks do
  @callback my_callback_with_a_when_clause(arg1) :: {:ok, arg1} when arg1: String.t()
  @callback my_callback_with_four_args(arg1 :: any(), list(), String.t(), opts :: Keyword.t()) ::
              integer()
  @callback my_callback_with_one_arg(arg1 :: any()) :: no_return
  @callback my_callback_with_no_arg() :: no_return

  def callback(at), do: Enum.at(callbacks(), at)
  def callbacks, do: @callback
end

defmodule Knigge.ASTTest do
  use ExUnit.Case, async: true

  import __MODULE__.TestModuleWithCallbacks, only: [callback: 1]

  describe ".function_spec_from_callback/1" do
    test "returns the correct name for a callback with no arguments" do
      assert Knigge.AST.function_spec_from_callback(callback(0)) == {:my_callback_with_no_arg, 0}
    end

    test "returns the correct name for a callback with 1 argument" do
      assert Knigge.AST.function_spec_from_callback(callback(1)) == {:my_callback_with_one_arg, 1}
    end

    test "returns the correct name for a callback with 4 arguments" do
      assert Knigge.AST.function_spec_from_callback(callback(2)) ==
               {:my_callback_with_four_args, 4}
    end

    test "returns the correct name for a callback with a when clausse" do
      assert Knigge.AST.function_spec_from_callback(callback(3)) ==
               {:my_callback_with_a_when_clause, 1}
    end
  end
end
