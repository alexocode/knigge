defmodule Knigge.OTP do
  @moduledoc false

  @otp_release :otp_release |> :erlang.system_info() |> List.to_string() |> String.to_integer()
  def release, do: @otp_release
end
