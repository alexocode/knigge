defmodule Knigge do
  alias Knigge.Generator

  defmacro __using__(implementation: impl) do
    quote do
      @implementation unquote(impl)
      @before_compile Knigge
      # @after_compile Knigge
    end
  end

  defmacro __before_compile__(%{module: module}) do
    delegate = Module.get_attribute(module, :implementation)

    module
    |> Module.get_attribute(:callback)
    |> Enum.map(&Generator.callback_to_defdelegate(&1, from: module, to: delegate))
  end
end

defmodule Test do
  use Knigge, implementation: TestImpl

  @callback test1(foo :: any()) :: any()
  @callback test2(bar :: any()) :: any()
  @callback test3(any(), opts :: Keyword.t()) :: any()
end

defmodule TestImpl do
  @behaviour Test

  def test1(arg1), do: IO.puts("Called test1/1 with: #{inspect(arg1)}")
  def test2(arg1), do: IO.puts("Called test2/1 with: #{inspect(arg1)}")
  def test3(arg1, arg2), do: IO.puts("Called test3/1 with: #{inspect(arg1)}, #{inspect(arg2)}")
end

Test.test1("foo")
Test.test2("test")
Test.test3(1337, 42)
