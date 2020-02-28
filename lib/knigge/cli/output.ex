defmodule Knigge.CLI.Output do
  @moduledoc false

  def info(message), do: Bunt.puts([:blue, message])
  def success(message), do: Bunt.puts([:green, message])
  def error(message), do: Bunt.warn([:red, message])
  def warn(message), do: Bunt.warn([:gold, message])
end
