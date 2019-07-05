defmodule Knigge.Options do
  import Keyword, only: [has_key?: 2]

  @type t :: [implementation: module()] | [otp_app: atom()]

  @spec validate!(t()) :: no_return
  def validate!(opts) do
    unless has_key?(opts, :implementation) or has_key?(opts, :otp_app) do
      raise ArgumentError,
            "Knigge expects either an :implementation or :otp_app key but neither was given."
    end
  end
end
