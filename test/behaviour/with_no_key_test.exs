defmodule Behaviour.WithNoKeyTest do
  use ExUnit.Case, async: true

  test "raises an ArgumentError with a descriptive error" do
    assert_raise ArgumentError,
                 "Knigge expects either an :implementation or :otp_app key but neither was given.",
                 fn ->
                   defmodule AnotherBehaviour do
                     use Knigge
                   end
                 end
  end
end
