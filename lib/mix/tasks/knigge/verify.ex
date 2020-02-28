defmodule Mix.Tasks.Knigge.Verify do
  use Mix.Task

  import Knigge.CLI.Output

  defmodule Context do
    @moduledoc false

    defstruct app: nil,
              modules: [],
              existing: [],
              missing: [],
              error: nil,
              began_at: nil
  end

  @recursive true

  @exit_codes %{
    unknown_app: 1,
    missing_module: 2
  }
  @exit_reasons Map.keys(@exit_codes)
  @unknown_error_code 64

  @impl Mix.Task
  def run(_args) do
    calling_app()
    |> run_for()
    |> exit_with()
  end

  defp calling_app do
    Mix.Task.run("compile")

    Mix.Project.get().project()[:app]
  end

  defp run_for(app) do
    began_at = current_millis()

    with {:ok, modules} <- fetch_modules_to_check(app) do
      %Context{
        app: calling_app(),
        modules: modules,
        began_at: began_at
      }
      |> begin()
      |> verify_implementations()
      |> finish()
    end
  end

  defp current_millis, do: :os.system_time(:millisecond)

  defp fetch_modules_to_check(app) do
    with :ok <- ensure_loaded(app),
         {:ok, modules} <- Knigge.Module.fetch_for_app(app) do
      {:ok, modules}
    else
      {:error, :undefined} ->
        error("Unable to load modules for #{app || "current app"}, are you sure the app exists?")

        {:error, :unknown_app}

      other ->
        other
    end
  end

  defp ensure_loaded(nil), do: {:error, :undefined}

  defp ensure_loaded(app) do
    case Application.load(app) do
      :ok -> :ok
      {:error, {:already_loaded, ^app}} -> :ok
      {:error, {'no such file or directory', _}} -> {:error, :undefined}
      other -> other
    end
  end

  defp begin(%Context{app: app, modules: modules} = context) do
    info("Verify #{length(modules)} Knigge facades in '#{app}'.")

    context
  end

  defp verify_implementations(%Context{app: app, modules: []} = context) do
    warn("\nNo modules in `#{app}` found which `use Knigge`.")

    context
  end

  defp verify_implementations(context) do
    context.modules
    |> Enum.map(&verify_implementation/1)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> merge_with_context(context)
  end

  defp verify_implementation(module) do
    case Knigge.Verify.implementation(module) do
      {:ok, implementation} -> {:existing, {module, implementation}}
      {:error, {:missing, implementation}} -> {:missing, {module, implementation}}
    end
  end

  defp merge_with_context(%{missing: _} = result, context) do
    context
    |> Map.put(:error, :missing_module)
    |> Map.merge(result)
  end

  defp merge_with_context(result, context), do: Map.merge(context, result)

  defp finish(context) do
    print_result(context)
    completed_in(context)

    maybe_error(context)
  end

  defp print_result(context) do
    print_existing(context)
    print_missing(context)
  end

  defp print_existing(%Context{existing: []}), do: :ok

  defp print_existing(%Context{existing: facades, modules: modules}) do
    success("\n#{length(facades)}/#{length(modules)} Facades passed:")

    facades
    |> Enum.map_join("\n", fn {module, implementation} ->
      "  #{inspect(module)} -> #{inspect(implementation)}"
    end)
    |> success()
  end

  defp print_missing(%Context{missing: []}), do: :ok

  defp print_missing(%Context{missing: facades, modules: modules}) do
    error("\n#{length(facades)}/#{length(modules)} Facades failed:")

    facades
    |> Enum.map_join("\n", fn {module, implementation} ->
      "  #{inspect(module)} -> #{inspect(implementation)}"
    end)
    |> error()
  end

  defp completed_in(%Context{began_at: began_at}) do
    duration = Float.round((current_millis() - began_at) / 1_000, 3)

    info("\nCompleted in #{duration} seconds.\n")
  end

  defp maybe_error(%Context{error: nil}), do: :ok
  defp maybe_error(%Context{error: reason}), do: {:error, reason}

  defp exit_with({:error, reason}) when reason in @exit_reasons do
    exit({:shutdown, @exit_codes[reason]})
  end

  defp exit_with({:error, unknown_reason}) do
    error("An unknown error occurred: #{inspect(unknown_reason)}")

    exit({:shutdown, @unknown_error_code})
  end

  defp exit_with(_), do: :ok
end
