defmodule Knigge.Implementation do
  def fetch!(module, opts) do
    opts
    |> Keyword.get(:implementation, fn ->
      opts
      |> Keyword.fetch!(:otp_app)
      |> from_env!(module)
    end)
    |> ensure_exists!(opts)
  end

  defp from_env!(app, behaviour), do: Application.fetch_env!(app, behaviour)

  defp ensure_exists!(module, opts) do
    unless Knigge.Module.exists?(module, opts) do
      Knigge.Error.implementation_not_loaded!(module, opts[:env])
    end

    module
  end
end
