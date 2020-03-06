defmodule Knigge.CLI.Output do
  @moduledoc false

  @device :stdio

  def info(device \\ @device, message), do: print(device, [:blue, message])
  def success(device \\ @device, message), do: print(device, [:green, message])
  def error(device \\ @device, message), do: print(device, [:red, message])
  def warn(device \\ @device, message), do: print(device, [:gold, message])

  def print(device \\ @device, message)

  def print(:stdio, message), do: Bunt.puts(message)
  def print(:stderr, message), do: Bunt.warn(message)
end
