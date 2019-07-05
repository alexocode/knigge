defmodule Knigge.Implementation do
  def fetch!(module, opts) do
    Keyword.get(opts, :implementation, fn ->
      opts
      |> Keyword.fetch!(:otp_app)
      |> from_env!(module)
    end)
  end

  defp from_env!(app, behaviour), do: Application.fetch_env!(app, behaviour)
end
