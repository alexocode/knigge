defmodule Knigge.VerificationTest do
  use ExUnit.Case, async: true

  alias Knigge.Verification
  alias Knigge.Verification.Context

  defmodule FacadeWithImpl do
    use Knigge, implementation: Knigge.VerificationTest.FacadeImpl

    @callback some_function() :: :ok
  end

  defmodule FacadeWithoutImpl do
    use Knigge,
      implementation: Does.Not.Exist,
      # Suppresses some warnings
      delegate_at_runtime?: true

    @callback some_function() :: :ok
  end

  defmodule FacadeImpl do
    @behaviour Knigge.VerificationTest.FacadeWithImpl

    def some_function, do: :ok
  end

  describe ".run/1" do
    test "returns a context without an error when passing a context with only `FacadeWithImpl`" do
      raw_context = %Context{app: :knigge, modules: [FacadeWithImpl]}
      context = Verification.run(raw_context)

      assert context.existing == [{FacadeWithImpl, FacadeImpl}]
      assert context.missing == []
      assert context.error == nil
    end

    test "returns a context containing an error when passing a context with `FacadeWithImpl` and `FacadeWithoutImpl`" do
      raw_context = %Context{app: :knigge, modules: [FacadeWithImpl, FacadeWithoutImpl]}
      context = Verification.run(raw_context)

      assert context.existing == [{FacadeWithImpl, FacadeImpl}]
      assert context.missing == [{FacadeWithoutImpl, Does.Not.Exist}]
      assert context.error == :missing_modules
    end
  end

  describe ".check_implementation/1" do
    test "returns :ok if the implementation exists" do
      assert Verification.check_implementation(FacadeWithImpl) == {:ok, FacadeImpl}
    end

    test "returns an error if the implementation is missing" do
      assert Verification.check_implementation(FacadeWithoutImpl) ==
               {:error, {:missing, Does.Not.Exist}}
    end
  end
end
