defmodule Knigge.Options do
  @defaults [
    delegate_at_runtime?: [only: :test],
    do_not_delegate: [],
    warn: true
  ]

  @moduledoc """
  Specifies valid `Knigge`-options and allows to validate and encapsulate the
  options in a struct.

  `Knigge` differentiates between **required** and _optional_ options:

  ## Required

  `Knigge` requires a way to determine the implementation to delegate to. As
  such it requires one of the following options (but not both):

  - `implementation` directly passes the implementation to delegate to
  - `otp_app` specifies the application for which the implementation has been configured

  If both or neither are given an `ArgumentError` is being raised.

  ## Optional

  These options do not have to be given but control aspects on how `Knigge` does
  delegation:

  ### `behaviour`
  The behaviour for which `Knigge` should generate delegations.

  __Default__: the `use`ing `__MODULE__`.

  ### `config_key`
  The configuration key from which `Knigge` should fetch the implementation.

  Is only used when `otp_app` is passed.

  __Default__: the `use`ing `__MODULE__`

  ### `default`
  A module which `Knigge` should use when no implementation was configured.

  Is only used when `otp_app` is passed.

  __Default__: `nil`; `Knigge` will raise an error when no implementation is configured.

  ### `delegate_at_runtime?`
  A switch to move delegation to runtime, by defauly `Knigge` does as much work as possible at compile time.
  Accepts:

  - a boolean (`true` always delegate at runtime | `false` always at compile time)
  - one or many environment names (atom or list of atoms) - only delegate at runtime in the given environments
  - `[only: <envs>]` - equivalent to the option above
  - `[except: <envs>]` - only delegates at runtime if the current environment is __not__ contained in the list

  __Default__: `Application.get_env(:knigge, :delegate_at_runtime?, #{inspect(@defaults[:delegate_at_runtime?])})`

  ### `do_not_delegate`
  A keyword list defining callbacks for which no delegation should happen.

  __Default__: `[]`

  ### `warn`
  Allows to control in which environments `Knigge` should generate warnings, use with care.
  Accepts:

  - a boolean (`true` always warns | `false` never warns)
  - one or many environment names (atom or list of atoms) - only warns in the given environments
  - `[only: <envs>]` - equivalent to the option above
  - `[except: <envs>]` - only warns if the current environment is __not__ contained in the list

  __Default__: `Application.get_env(:knigge, :warn, #{inspect(@defaults[:warn])})`
  """

  import Keyword, only: [has_key?: 2, keyword?: 1]

  @type raw :: [required() | list(optional())]

  @type required :: {:implementation, module()} | {:otp_app, otp_app()}
  @type optional :: [
          behaviour: behaviour(),
          config_key: config_key(),
          default: default(),
          delegate_at_runtime?: boolean_or_envs(),
          do_not_delegate: do_not_delegate(),
          warn: boolean_or_envs()
        ]

  @type behaviour :: module()
  @type boolean_or_envs :: boolean() | envs() | [only: envs()] | [except: envs()]
  @type config_key :: atom()
  @type default :: nil | module()
  @type delegate_at :: :compile_time | :runtime
  @type do_not_delegate :: keyword(arity())
  @type envs :: atom() | list(atom())
  @type otp_app :: atom()

  @type t :: %__MODULE__{
          implementation: module() | {:config, otp_app(), config_key()},
          behaviour: behaviour(),
          default: default(),
          delegate_at_runtime?: boolean(),
          do_not_delegate: do_not_delegate(),
          warn: boolean()
        }

  defstruct [
    :behaviour,
    :default,
    :delegate_at_runtime?,
    :do_not_delegate,
    :implementation,
    :warn
  ]

  @doc """
  Checks the validity of the given opts (`validate!/1`), applies defaults and
  puts them into the `#{inspect(__MODULE__)}`-struct.
  """
  @spec new(options :: raw()) :: t()
  def new(opts) do
    env = Keyword.get_lazy(opts, :env, &env/0)

    opts =
      opts
      |> map_deprecated()
      |> validate!()
      |> with_defaults()
      |> transform(with_env: env)

    struct(__MODULE__, opts)
  end

  defp env do
    if function_exported?(Mix, :env, 0) do
      Mix.env()
    else
      :prod
    end
  end

  defp map_deprecated(opts) when is_list(opts) do
    opts
    |> Enum.map(fn {key, _} = kv ->
      case map_deprecated(kv) do
        ^kv ->
          kv

        {new_key, _} = kv when is_atom(new_key) ->
          IO.warn("Knigge encountered the deprecated option `#{key}`, please use `#{new_key}`.")

          kv

        message when is_binary(message) ->
          IO.warn(
            "Knigge encountered the deprecated option `#{key}`, this option is no longer supported; #{message}."
          )

          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp map_deprecated({key, _})
       when key in [:check_if_exists, :check_if_exists?],
       do: "please use the mix task `mix knigge.verify`"

  defp map_deprecated({:delegate_at, :compile_time}), do: {:delegate_at_runtime?, false}
  defp map_deprecated({:delegate_at, :runtime}), do: {:delegate_at_runtime?, true}

  defp map_deprecated(other), do: other

  @doc """
  Applies the defaults to the given options:
  #{@defaults |> Enum.map(fn {key, value} -> "  - #{key} = #{inspect(value)}" end) |> Enum.join("\n")}
  """
  @spec with_defaults(raw()) :: raw()
  def with_defaults(opts) do
    @defaults
    |> Keyword.merge(defaults_from_config())
    |> Keyword.merge(opts)
    |> Keyword.put_new_lazy(:implementation, fn ->
      {:config, opts[:otp_app], List.wrap(opts[:config_key])}
    end)
  end

  defp defaults_from_config do
    :knigge
    |> Application.get_all_env()
    |> Keyword.take([:delegate_at_runtime?, :warn])
  end

  defp transform(opts, with_env: env) when is_list(opts) do
    for {key, value} <- opts, do: {key, transform(key, value, with_env: env)}
  end

  defp transform(key, envs, with_env: env)
       when key in [:delegate_at_runtime?, :warn],
       do: active_env?(env, envs)

  defp transform(:config_key, value, with_env: _), do: List.wrap(value)

  defp transform(_key, value, with_env: _), do: value

  defp active_env?(_env, boolean) when is_boolean(boolean), do: boolean
  defp active_env?(env, only: envs), do: env in List.wrap(envs)
  defp active_env?(env, except: envs), do: env not in List.wrap(envs)
  defp active_env?(env, envs), do: active_env?(env, only: envs)

  @doc """
  Validates the options passed to `Knigge`. It ensures that the required keys
  are present and that no unknown keys are passed to `Knigge` which might
  indicate a spelling error.

  See the moduledocs for details on required and optional options.

  ## Examples

      iex> Knigge.Options.validate!([1, 2, 3])
      ** (ArgumentError) Knigge expects a keyword list as options, instead received: [1, 2, 3]

      iex> Knigge.Options.validate!([])
      ** (ArgumentError) Knigge expects either the :implementation or the :otp_app option but neither was given.

      iex> Knigge.Options.validate!(implementation: SomeModule)
      [implementation: SomeModule]

      iex> Knigge.Options.validate!(otp_app: :knigge)
      [otp_app: :knigge]

      iex> Knigge.Options.validate!(implementation: SomeModule, otp_app: :knigge)
      ** (ArgumentError) Knigge expects either the :implementation or the :otp_app option but both were given.

      iex> Knigge.Options.validate!(otp_app: :knigge, the_answer_to_everything: 42, another_weird_option: 1337)
      ** (ArgumentError) Knigge received unexpected options: [the_answer_to_everything: 42, another_weird_option: 1337]

      iex> Knigge.Options.validate!(otp_app: "knigge")
      ** (ArgumentError) Knigge received invalid value for `otp_app`. Expected atom but received: "knigge"

      iex> Knigge.Options.validate!(otp_app: :knigge, delegate_at_runtime?: "test")
      ** (ArgumentError) Knigge received invalid value for `delegate_at_runtime?`. Expected boolean or environment (atom or list of atoms) but received: "test"
  """
  @spec validate!(opts :: raw()) :: no_return | opts when opts: raw()
  def validate!(opts) do
    validate_keyword!(opts)
    validate_required!(opts)
    validate_known!(opts)
    validate_values!(opts)

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
    case {has_key?(opts, :implementation), has_key?(opts, :otp_app)} do
      {false, false} ->
        raise ArgumentError,
              "Knigge expects either the :implementation or the :otp_app option but neither was given."

      {true, true} ->
        raise ArgumentError,
              "Knigge expects either the :implementation or the :otp_app option but both were given."

      _ ->
        :ok
    end
  end

  defp validate_known!(opts) do
    opts
    |> Enum.reject(&known?/1)
    |> case do
      [] ->
        :ok

      unknown ->
        raise ArgumentError, "Knigge received unexpected options: #{inspect(unknown)}"
    end
  end

  defp validate_values!(opts) do
    opts
    |> Enum.reject(&valid_value?/1)
    |> case do
      [] ->
        :ok

      [{name, value} | _] ->
        raise ArgumentError,
              "Knigge received invalid value for `#{name}`. " <>
                "Expected #{expected_value(name)} but received: #{inspect(value)}"
    end
  end

  @option_types [
    behaviour: :module,
    default: :module,
    delegate_at_runtime?: :envs,
    do_not_delegate: :keyword,
    implementation: :module,
    otp_app: :atom,
    config_key: [:atom, {:list_of, :atom}],
    warn: :envs
  ]

  @option_names Keyword.keys(@option_types)

  defp known?({name, _}), do: name in @option_names

  defp valid_value?({name, value}) do
    @option_types
    |> Keyword.fetch!(name)
    |> valid_value?(value)
  end

  defp valid_value?(types, value) when is_list(types),
    do: Enum.any?(types, fn type -> valid_value?(type, value) end)

  defp valid_value?({:list_of, type}, values),
    do: is_list(values) && Enum.all?(values, fn value -> valid_value?(type, value) end)

  defp valid_value?(:atom, value), do: is_atom(value)
  defp valid_value?(:module, value), do: is_atom(value)
  defp valid_value?(:keyword, value), do: Keyword.keyword?(value)
  defp valid_value?(:envs, only: envs), do: valid_envs?(envs)
  defp valid_value?(:envs, except: envs), do: valid_envs?(envs)
  defp valid_value?(:envs, envs), do: valid_envs?(envs)

  defp valid_envs?(envs) do
    is_boolean(envs) or is_atom(envs) or (is_list(envs) and Enum.all?(envs, &is_atom/1))
  end

  defp expected_value(name) do
    case Keyword.fetch!(@option_types, name) do
      :envs ->
        "boolean or environment (atom or list of atoms)"

      :keyword ->
        "keyword list"

      # For now we explicitly match on the "or" option, as soon as we add further
      # "or"ed options this ought to be refactored to something more general purpose
      [:atom, {:list_of, :atom}] ->
        "atom or list of atoms"

      other ->
        to_string(other)
    end
  end
end
