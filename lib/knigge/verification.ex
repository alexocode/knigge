defmodule Knigge.Verification do
  @moduledoc false

  alias __MODULE__.Context

  @doc """
  Runs all verifications for the given `#{inspect(Context)}`.

  At the moment this only consists of checking whether or not the Implementations exist.
  """
  @spec run(Context.t()) :: Context.t()
  def run(%Context{} = context) do
    verify_implementations(context)
  end

  defp verify_implementations(context) do
    context.modules
    |> Enum.map(&verify_implementation/1)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> merge_with_context(context)
  end

  defp verify_implementation(module) do
    case check_implementation(module) do
      {:ok, implementation} -> {:existing, {module, implementation}}
      {:error, {:missing, implementation}} -> {:missing, {module, implementation}}
    end
  end

  defp merge_with_context(%{missing: _} = result, context) do
    context
    |> Map.put(:error, :missing_modules)
    |> Map.merge(result)
  end

  defp merge_with_context(result, context), do: Map.merge(context, result)

  @doc """
  Checks if the given `Knigge` module's implementation exists. Returns an error if not.
  """
  @spec check_implementation(module :: module()) ::
          {:ok, implementation :: module()}
          | {:error, {:missing, implementation :: module()}}
  def check_implementation(module) do
    implementation = module.__knigge__(:implementation)

    if Knigge.Module.exists?(implementation) do
      {:ok, implementation}
    else
      {:error, {:missing, implementation}}
    end
  end
end
