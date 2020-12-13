defmodule Behaviour.WithOtpAppKey do
  use ExUnit.Case

  import Knigge.Test.SaltedModule

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
    Application.put_env(:knigge, :working_behaviour, SomeModule)

    # Should not raise
    behaviour =
      defmodule_salted WorkingBehaviour do
        use Knigge,
          otp_app: :knigge,
          config_key: :working_behaviour
      end

    Application.delete_env(:knigge, :working_behaviour)

    assert behaviour.__knigge__(:implementation) == SomeModule
  end

  test "works fine with a default" do
    # Should not raise
    behaviour =
      defmodule_salted WorkingBehaviour do
        use Knigge,
          otp_app: :knigge,
          default: MyApp.SomeModule
      end

    Application.delete_env(:knigge, :working_behaviour)

    assert behaviour.__knigge__(:implementation) == MyApp.SomeModule
  end

  test "calling my_function/1 delegates the call to the implementation" do
    Application.put_env(:knigge, __MODULE__.AGreatBehaviour, AGreatBehaviourMock)

    # Should not raise
    defmodule AGreatBehaviour do
      use Knigge, otp_app: :knigge

      @callback my_function(arg :: any()) :: no_return
    end

    Application.delete_env(:knigge, __MODULE__.AGreatBehaviour)

    Mox.defmock(AGreatBehaviourMock, for: AGreatBehaviour)
    Mox.expect(AGreatBehaviourMock, :my_function, fn arg -> send self(), {:argument, arg} end)

    AGreatBehaviour.my_function("with some argument")

    assert_receive {:argument, "with some argument"}

    Mox.verify!(AGreatBehaviourMock)
  end
end
