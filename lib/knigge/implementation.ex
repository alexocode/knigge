defmodule Knigge.Implementation do
  @moduledoc """
  Internal module to work with the supplied implementation.

  Fetches the implementing modules based on the `Knigge.Options.implementation`
  value. Currently it supports passing the implementation directly or fetching
  it from the application environment.
  """

  alias Knigge.Options

  def fetch!(%Options{implementation: {:config, otp_app, [key | keys]}, default: default}) do
    with nil <- otp_app |> env!(key, default) |> get(keys) do
      raise ArgumentError,
        message: """
        could not fetch application environment #{inspect([key | keys])} \
        for application #{inspect(otp_app)}\
        """
    end
  end

  def fetch!(%Options{implementation: implementation}) do
    implementation
  end

  def fetch_for!(module) do
    module
    |> Knigge.options!()
    |> Knigge.Implementation.fetch!()
  end

  defp env!(otp_app, key, nil), do: Application.fetch_env!(otp_app, key)

  defp env!(otp_app, key, default), do: Application.get_env(otp_app, key, default)

  defp get(nil, _keys), do: nil

  defp get(data, []), do: data

  defp get(data, keys), do: get_in(data, keys)
end
