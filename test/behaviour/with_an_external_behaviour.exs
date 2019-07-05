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
end
