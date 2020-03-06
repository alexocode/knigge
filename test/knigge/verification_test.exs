defmodule Knigge.VerificationTest do
  use ExUnit.Case, async: true

  defmodule FacadeWithImpl do
    use Knigge, implementation: Knigge.VerificationTest.FacadeImpl

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
    @behaviour Knigge.VerificationTest.FacadeWithImpl

    def some_function, do: :ok
  end

  describe ".check_implementation/1" do
    test "returns :ok if the implementation exists" do
      assert Knigge.Verification.check_implementation(FacadeWithImpl) == {:ok, FacadeImpl}
    end

    test "returns an error if the implementation is missing" do
      assert Knigge.Verification.check_implementation(FacadeWithoutImpl) ==
               {:error, {:missing, Does.Not.Exist}}
    end
  end
end
