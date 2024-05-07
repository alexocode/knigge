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

  test "raises an ArgumentError with an invalid :config_key" do
    Application.put_env(:knigge, :foo, SomeModule)

    message = ~r/could not fetch .* :bar for application :knigge because .* :bar was not set/

    assert_raise ArgumentError, message, fn ->
      defmodule MissingConfig do
        use Knigge,
          otp_app: :knigge,
          config_key: :bar
      end
    end
  end

  test "raises an ArgumentError with an invalid :config_key path" do
    Application.put_env(:knigge, :foo, module: SomeModule)
    message = ~r/could not fetch application environment \[:foo, :bar\] for application :knigge.*/

    assert_raise ArgumentError, message, fn ->
      defmodule MissingConfig do
        use Knigge,
          otp_app: :knigge,
          config_key: [:foo, :bar]
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

  test "works fine with config_key path being set in the Application environment" do
    Application.put_env(:knigge, :sys, module: SomeModule)

    # Should not raise
    behaviour =
      defmodule_salted WorkingBehaviour do
        use Knigge,
          otp_app: :knigge,
          config_key: [:sys, :module]
      end

    Application.delete_env(:knigge, :sys, module: SomeModule)

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

    assert behaviour.__knigge__(:implementation) == MyApp.SomeModule
  end

  test "ignores default if module is in config" do
    Application.put_env(:knigge, :working_behaviour, SomeModule)

    # Should not raise
    behaviour =
      defmodule_salted WorkingBehaviour do
        use Knigge,
          otp_app: :knigge,
          config_key: :working_behaviour,
          default: AnotherModule
      end

    Application.delete_env(:knigge, :working_behaviour)

    assert behaviour.__knigge__(:implementation) == SomeModule
  end

  test "ignores default if module is in config_key path" do
    Application.put_env(:knigge, :sys, module: SomeModule)

    # Should not raise
    behaviour =
      defmodule_salted WorkingBehaviour do
        use Knigge,
          otp_app: :knigge,
          config_key: [:sys, :module],
          default: AnotherModule
      end

    Application.delete_env(:knigge, :sys, module: SomeModule)

    assert behaviour.__knigge__(:implementation) == SomeModule
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
