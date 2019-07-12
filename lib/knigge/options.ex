defmodule Knigge.Options do
  @moduledoc false

  import Keyword, only: [has_key?: 2, keyword?: 1]

  @type t :: [required() | list(optional())]
  @type required :: {:implementation, module()} | {:otp_app, atom()}
  @type optional :: [do_not_delegate: keyword(arity())]

  @doc """
  Validates the options passed to `Knigge`. It ensures that the required keys
  are present and that no unknown keys are passed to `Knigge` which might
  indicate a spelling error.

  Required: `implementation` or `otp_app`
  Optional: `do_not_delegate`

  ## Examples

      iex> Knigge.Options.validate!([1, 2, 3])
      ** (ArgumentError) Knigge expects a keyword list as options, instead received: [1, 2, 3]

      iex> Knigge.Options.validate!([])
      ** (ArgumentError) Knigge expects either an :implementation or :otp_app key but neither was given.

      iex> Knigge.Options.validate!(implementation: SomeModule)
      [implementation: SomeModule]

      iex> Knigge.Options.validate!(otp_app: :knigge)
      [otp_app: :knigge]

      iex> Knigge.Options.validate!(otp_app: :knigge, the_answer_to_everything: 42, another_weird_option: 1337)
      ** (ArgumentError) Knigge received unexpected options: [the_answer_to_everything: 42, another_weird_option: 1337]
  """
  @spec validate!(t()) :: no_return
  def validate!(opts) do
    validate_keyword!(opts)
    validate_required!(opts)
    validate_known!(opts)

    opts
  end

  defp validate_keyword!(opts) do
    unless keyword?(opts) do
      raise ArgumentError,
            "Knigge expects a keyword list as options, instead received: #{inspect(opts)}"
    end

    :ok
  end

  defp validate_required!(opts) do
    unless has_key?(opts, :implementation) or has_key?(opts, :otp_app) do
      raise ArgumentError,
            "Knigge expects either an :implementation or :otp_app key but neither was given."
    end

    :ok
  end

  defp validate_known!(opts) do
    opts
    |> Enum.reject(&known_option?/1)
    |> case do
      [] ->
        :ok

      unknown ->
        raise ArgumentError, "Knigge received unexpected options: #{inspect(unknown)}"
    end
  end

  defp known_option?({name, _}), do: known_option?(name)
  defp known_option?(name), do: name in [:implementation, :otp_app, :do_not_delegate]
end
