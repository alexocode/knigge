defmodule TheBehaviour do
  @callback my_function() :: no_return
end

Mox.defmock(TheImplementation, for: TheBehaviour)

defmodule TheFacade do
  use Knigge,
    behaviour: TheBehaviour,
    implementation: TheImplementation
end

defmodule Behaviour.WithAnExternalBehaviour do
  use ExUnit.Case, async: true

  import Mox

  test "calling TheFacade.__knigge__(:behaviour) returns TheBehaviour" do
    assert TheFacade.__knigge__(:behaviour) == TheBehaviour
  end

  test "calling TheFacade.__knigge__(:implementation) returns TheImplementation" do
    assert TheFacade.__knigge__(:implementation) == TheImplementation
  end

  test "calling Facade.my_function invokes the function on the Implementation" do
    expect(TheImplementation, :my_function, fn -> :ok end)

    assert :ok = TheFacade.my_function()

    verify!(TheImplementation)
  end
end
