defmodule Knigge.Verify do
  @moduledoc false

  @doc """
  Checks if the given `Knigge` module's implementation exists. Returns an error if not.
  """
  @spec implementation(module :: module()) ::
          {:ok, implementation :: module()}
          | {:error, {:missing, implementation :: module()}}
  def implementation(module) do
    implementation = module.__knigge__(:implementation)

    if Knigge.Module.exists?(implementation) do
      {:ok, implementation}
    else
      {:error, {:missing, implementation}}
    end
  end
end
