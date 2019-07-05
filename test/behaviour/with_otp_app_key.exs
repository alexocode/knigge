defmodule Behaviour.WithOtpAppKey do
  use ExUnit.Case, async: true

  test "raises an ArgumentError without a relevant configuration available" do
    assert_raise ArgumentError,
                 ~r/could not fetch application environment #{inspect(__MODULE__)}.RaisingBehaviour for application :missing/,
                 fn ->
                   defmodule RaisingBehaviour do
                     use Knigge, otp_app: :missing
                   end
                 end
  end

  test "works fine with the relevant configuration being set in the Application environment" do
    Application.put_env(:knigge, __MODULE__.WorkingBehaviour, SomeModule)

    # Should not raise
    defmodule WorkingBehaviour do
      use Knigge, otp_app: :knigge
    end

    assert WorkingBehaviour.__knigge__(:implementation) == SomeModule
  end
end
