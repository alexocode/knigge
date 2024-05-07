defmodule Knigge.OptionsTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias Knigge.Options

  doctest Options

  test "using `check_if_exists` prints a deprecation warning" do
    warnings = capture_io(:stderr, fn -> valid_opts(check_if_exists: true) end)

    assert warnings =~
             "Knigge encountered the deprecated option `check_if_exists`, " <>
               "this option is no longer supported; " <>
               "please use the mix task `mix knigge.verify`."
  end

  test "using `check_if_exists?` prints a deprecation warning" do
    warnings = capture_io(:stderr, fn -> valid_opts(check_if_exists?: true) end)

    assert warnings =~
             "Knigge encountered the deprecated option `check_if_exists?`, " <>
               "this option is no longer supported; " <>
               "please use the mix task `mix knigge.verify`."
  end

  test "using `delegate_at` prints a deprecation warning" do
    warnings = capture_io(:stderr, fn -> valid_opts(delegate_at: :runtime) end)

    assert warnings =~
             "Knigge encountered the deprecated option `delegate_at`, please use `delegate_at_runtime?`."
  end

  test "raises an exception for an invalid `default` value" do
    message =
      "Knigge received invalid value for `default`. Expected module but received: \"invalid\""

    assert_raise ArgumentError, message, fn ->
      valid_opts(default: "invalid")
    end
  end

  defp valid_opts(opts) do
    [behaviour: SomeModule, implementation: AnotherModule]
    |> Keyword.merge(opts)
    |> Options.new()
  end
end
