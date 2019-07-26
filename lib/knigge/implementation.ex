defmodule Knigge.Implementation do
  alias Knigge.Options

  def fetch!(%Options{implementation: {:config, otp_app, key}}) do
    Application.fetch_env!(otp_app, key)
  end

  def fetch!(%Options{implementation: implementation}) do
    implementation
  end
end
