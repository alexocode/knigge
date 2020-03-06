defmodule Knigge.Implementation do
  @moduledoc """
  Internal module to work with the supplied implementation.

  Fetches the implementing modules based on the `Knigge.Options.implementation`
  value. Currently it supports passing the implementation directly or fetching
  it from the application environment.
  """

  alias Knigge.Options

  def fetch!(%Options{implementation: {:config, otp_app, key}}) do
    Application.fetch_env!(otp_app, key)
  end

  def fetch!(%Options{implementation: implementation}) do
    implementation
  end

  def fetch_for!(module) do
    module
    |> Knigge.options!()
    |> Knigge.Implementation.fetch!()
  end
end
