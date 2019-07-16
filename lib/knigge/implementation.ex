defmodule Knigge.Implementation do
  def fetch!(module, opts) do
    opts
    |> Keyword.get(:implementation, fn ->
      config_key = Keyword.get(opts, :config_key, module)

      opts
      |> Keyword.fetch!(:otp_app)
      |> from_env!(config_key)
    end)
    |> ensure_exists!(opts)
  end

  defp from_env!(app, config_key), do: Application.fetch_env!(app, config_key)

  defp ensure_exists!(module, opts) do
    unless Knigge.Module.exists?(module, opts) do
      Knigge.Error.implementation_not_loaded!(module, opts[:env])
    end

    module
  end
end
