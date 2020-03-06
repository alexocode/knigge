defmodule Mix.Tasks.Knigge.Verify do
  use Mix.Task

  import Knigge.CLI.Output

  alias Knigge.Verification
  alias Knigge.Verification.Context

  require Context

  @recursive true

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("compile")

    calling_app()
    |> run_for()
    |> exit_with()
  end

  defp calling_app, do: Mix.Project.get().project()[:app]

  defp run_for(app) do
    with {:ok, context} <- Context.for_app(app) do
      context
      |> begin_verification()
      |> Verification.run()
      |> finish_verification()
    else
      {:error, {:unknown_app, app}} ->
        error("Unable to load modules for #{app || "current app"}, are you sure the app exists?")

        {:error, :unknown_app}

      other ->
        other
    end
  end

  defp begin_verification(%Context{modules: []} = context) do
    warn("No modules in `#{app}` found which `use Knigge`.")

    context
  end

  defp begin_verification(%Context{app: app, modules: modules} = context) do
    info("Verify #{length(modules)} Knigge facades in '#{app}'.")

    context
  end

  defp finish_verification(context) do
    context
    |> print_result()
    |> completed_in()
  end

  defp print_result(context) do
    print_existing(context)
    print_missing(context)

    context
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
      "  #{inspect(module)} -> #{inspect(implementation)} (implementation does not exist)"
    end)
    |> error()
  end

  defp completed_in(context) do
    context = Context.finished(context)

    duration =
      context
      |> Context.duration()
      |> Kernel./(1_000)
      |> Float.round(3)

    info("\nCompleted in #{duration} seconds.\n")

    context
  end

  defp exit_with(%Context{error: :missing_modules} = context) do
    error(
      :stderr,
      "Validation failed for #{length(context.missing)}/#{length(context.modules)} facades."
    )

    exit_with({:error, :missing_modules})
  end

  defp exit_with(%Context{} = context) when Context.is_error(context) do
    exit_with({:error, context.error})
  end

  @exit_codes %{unknown_app: 1, missing_modules: 2}
  @exit_reasons Map.keys(@exit_codes)
  defp exit_with({:error, reason}) when reason in @exit_reasons do
    exit({:shutdown, @exit_codes[reason]})
  end

  @unknown_error_code 64
  defp exit_with({:error, unknown_reason}) do
    error("An unknown error occurred: #{inspect(unknown_reason)}")

    exit({:shutdown, @unknown_error_code})
  end

  defp exit_with(_), do: :ok
end
