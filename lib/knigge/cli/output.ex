defmodule Knigge.CLI.Output do
  @moduledoc false

  def linebreak, do: IO.puts("")

  def info(message, meta), do: Bunt.puts([:blue, format(message, meta)])
  def success(message, meta), do: Bunt.puts([:green, format(message, meta)])
  def error(message, meta), do: Bunt.warn([:red, format(message, meta)])
  def warn(message, meta), do: Bunt.warn([:gold, format(message, meta)])

  def format(message, app: app) do
    ["[#{app}] ", message]
  end
end
