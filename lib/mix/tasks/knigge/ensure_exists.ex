defmodule Mix.Tasks.Knigge.EnsureExists do
  use Mix.Task

  import Knigge.CLI.Output

  @recursive true

  @exit_codes %{
    unknown_app: 1,
    missing_module: 2
  }
  @exit_reasons Map.keys(@exit_codes)
  @unknown_error_code 64

  @impl Mix.Task
  def run(_args) do
    began_at = current_millis()
    app = calling_app()

    app
    |> begin()
    |> fetch_modules_to_check()
    |> verify_implementations(app)
    |> finish(app, began_at)
    |> exit_with(app)
  end

  defp current_millis, do: :os.system_time(:millisecond)

  defp calling_app, do: Mix.Project.get().project()[:app]

  defp begin(app) do
    info("Verify Knigge implementations.", app: app)

    app
  end

  defp fetch_modules_to_check(app) do
    Mix.Task.run("compile")

    with :ok <- ensure_loaded(app),
         {:error, :undefined} <- Knigge.Module.fetch_for_app(app) do
      error("Unable to load modules for #{app}, are you sure the app exists?", app: app)

      {:error, :unknown_app}
    end
  end

  defp ensure_loaded(app) do
    case Application.load(app) do
      :ok -> :ok
      {:error, {:already_loaded, ^app}} -> :ok
      other -> other
    end
  end

  defp verify_implementations({:ok, []}, app) do
    warn("No modules in `#{app}` found which `use Knigge`.", app: app)

    :ok
  end

  defp verify_implementations({:ok, modules}, app) do
    Enum.reduce(modules, :ok, fn module, result ->
      module
      |> verify_implementation(app)
      |> to_result(result)
    end)
  end

  defp verify_implementations(other, _app), do: other

  defp verify_implementation(module, app) do
    implementation = module.__knigge__(:implementation)

    if Knigge.Module.exists?(implementation) do
      success("#{inspect(module)} -> #{inspect(implementation)} (exists)", app: app)
    else
      error("#{inspect(module)} -> #{inspect(implementation)} (missing)", app: app)
    end
  end

  defp to_result(:ok, result), do: result
  defp to_result({:error, _} = error, _result), do: error

  defp finish(result, app, began_at) do
    duration = Float.round((current_millis() - began_at) / 1_000, 3)

    info("Completed in #{duration} seconds.", app: app)
    linebreak()

    result
  end

  defp exit_with({:error, reason}, _app) when reason in @exit_reasons do
    exit({:shutdown, @exit_codes[reason]})
  end

  defp exit_with({:error, unknown_reason}, app) do
    error("An unknown error occurred: #{inspect(unknown_reason)}", app: app)

    exit({:shutdown, @unknown_error_code})
  end

  defp exit_with(_, _app), do: :ok
end
