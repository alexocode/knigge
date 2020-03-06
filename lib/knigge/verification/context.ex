defmodule Knigge.Verification.Context do
  @moduledoc false

  @type t :: %__MODULE__{
          app: atom(),
          modules: list(module()),
          existing: list(facade_with_module()),
          missing: list(facade_with_module()),
          error: nil | any(),
          began_at: milliseconds(),
          finished_at: milliseconds()
        }
  @type facade_with_module :: {facade :: module(), impl :: module()}
  @type milliseconds :: non_neg_integer()
  defstruct app: nil,
            modules: [],
            existing: [],
            missing: [],
            error: nil,
            began_at: nil,
            finished_at: nil

  module = inspect(__MODULE__)

  @spec new() :: t()
  @spec new(params :: map() | Keyword.t()) :: t()
  def new(params \\ %{})

  def new(params) when is_list(params) do
    params |> Map.new() |> new()
  end

  def new(params) do
    struct!(__MODULE__, with_defaults(params))
  end

  defp with_defaults(params) do
    Map.put_new(params, :began_at, current_millis())
  end

  defp current_millis, do: :os.system_time(:millisecond)

  @doc """
  Loads the modules for the given app which `use Knigge`.

  Returns an error when the app does not exist or loading it fails.

  ## Example

      iex> {:ok, context} = #{module}.for_app(:knigge)
      iex> context.app
      :knigge
      iex> context.modules
      []

      iex> context = %#{module}{began_at: 123}
      iex> {:ok, context} = #{module}.for_app(context, :knigge)
      iex> context.began_at
      123
      iex> context.app
      :knigge
      iex> context.modules
      []

      iex> #{module}.for_app(:does_not_exist)
      {:error, {:unknown_app, :does_not_exist}}
  """
  @spec for_app(app :: atom()) :: {:ok, t()} | {:error, reason :: any()}
  @spec for_app(t(), app :: atom()) :: {:ok, t()} | {:error, reason :: any()}
  def for_app(context \\ new(), app)

  def for_app(%__MODULE__{} = context, app) do
    with :ok <- ensure_loaded(app),
         {:ok, modules} <- Knigge.Module.fetch_for_app(app) do
      {:ok, %__MODULE__{context | app: app, modules: modules}}
    end
  end

  defp ensure_loaded(nil), do: {:error, {:unknown_app, nil}}

  defp ensure_loaded(app) do
    case Application.load(app) do
      :ok -> :ok
      {:error, {:already_loaded, ^app}} -> :ok
      {:error, {'no such file or directory', _}} -> {:error, {:unknown_app, app}}
      {:error, :undefined} -> {:error, {:unknown_app, app}}
      other -> other
    end
  end

  @doc """
  Sets the `finished_at` field to the given time in milliseconds.

  If none was given it uses the current time.

  ## Examples

      iex> context = %#{module}{finished_at: nil}
      iex> context = #{module}.finished(context)
      iex> context.finished_at <= :os.system_time(:millisecond)
      true

      iex> context = %#{module}{finished_at: nil}
      iex> context = #{module}.finished(context, 123)
      iex> context.finished_at
      123

      iex> context = %#{module}{finished_at: 123}
      iex> new_context = #{module}.finished(context)
      iex> context.finished_at != new_context.finished_at
      true
  """
  @spec finished(t()) :: t()
  @spec finished(t(), milliseconds()) :: t()
  def finished(%__MODULE__{} = context, finished_at \\ current_millis()) do
    %__MODULE__{context | finished_at: finished_at}
  end

  @doc """
  Returns the duration between `began_at` and `finished_at`. Uses the current
  time if `finished_at` is `nil`.

  ## Examples

      iex> context = %#{module}{began_at: 100, finished_at: 110}
      iex> #{module}.duration(context)
      10

      iex> now = :os.system_time(:millisecond)
      iex> context = %#{module}{began_at: now - 100}
      iex> duration = #{module}.duration(context)
      iex> duration >= 100
      true
  """
  @spec duration(t()) :: milliseconds()
  def duration(%__MODULE__{began_at: began_at, finished_at: finished_at}) do
    (finished_at || current_millis()) - began_at
  end

  @doc """
  Returns whether or not this context is considered an error.

  ## Examples

      iex> context = %#{module}{error: nil}
      iex> #{module}.error?(context)
      false

      iex> context = %#{module}{error: :some_error}
      iex> #{module}.error?(context)
      true
  """
  @spec error?(t()) :: boolean()
  def error?(%__MODULE__{error: error}), do: not is_nil(error)
end
