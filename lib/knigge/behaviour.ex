defmodule Knigge.Behaviour do
  @moduledoc """
  Internal module to work with the supplied behaviour.

  Can be used to fetch the behaviour from the `Knigge.Options`-struct and to
  access the callbacks defined by the behaviour.

  It works whether the module is already compiled or still open, for which it
  uses `Module.open?/1`. If the module is still open it directly accesses the
  module attribute `:callback` by calling `Module.get_attribute/2` and then
  using `Knigge.AST.function_spec_from_callback/1` to transform the AST into a
  function spec, such as `{:my_function, 2}` which is being returned as a
  Keyword list.
  """

  alias Knigge.Options

  def fetch!(%Options{behaviour: behaviour}) do
    behaviour
  end

  def callbacks(module) do
    if Module.open?(module) do
      callbacks_from_attribute(module)
    else
      module.behaviour_info(:callbacks)
    end
  end

  defp callbacks_from_attribute(module) do
    module
    |> Module.get_attribute(:callback)
    |> Enum.map(&Knigge.AST.function_spec_from_callback/1)
    |> Enum.uniq()
  end

  def optional_callbacks(module) do
    if Module.open?(module) do
      module
      |> Module.get_attribute(:optional_callbacks)
      |> List.wrap()
      |> List.flatten()
    else
      module.behaviour_info(:optional_callbacks)
    end
  end
end
