defmodule Knigge.VerifyTest do
  use ExUnit.Case, async: true

  defmodule FacadeWithImpl do
    use Knigge, implementation: Knigge.VerifyTest.FacadeImpl

    @callback some_function() :: :ok
  end

  defmodule FacadeWithoutImpl do
    use Knigge,
      implementation: Does.Not.Exist,
      # Surpresses some warnings
      delegate_at_runtime?: true

    @callback some_function() :: :ok
  end

  defmodule FacadeImpl do
    @behaviour Knigge.VerifyTest.FacadeWithImpl

    def some_function, do: :ok
  end

  describe ".implementation/1" do
    test "returns :ok if the implementation exists" do
      assert Knigge.Verify.implementation(FacadeWithImpl) == {:ok, FacadeImpl}
    end

    test "returns an error if the implementation is missing" do
      assert Knigge.Verify.implementation(FacadeWithoutImpl) ==
               {:error, {:missing, Does.Not.Exist}}
    end
  end
end
