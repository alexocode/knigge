defmodule Mix.Tasks.Knigge.EnsureExists do
  use Mix.Task

  @exit_codes %{
    unknown_app: 1,
    missing_module: 2
  }
  @exit_reasons Map.keys(@exit_codes)
  @unknown_error_code 64

  @impl Mix.Task
  def run(_args) do
    calling_app()
    |> fetch_modules_to_check()
    |> check_if_implementations_exist()
    |> exit_with()
  end

  defp calling_app, do: Mix.Project.get().project()[:app]

  defp fetch_modules_to_check(app) do
    with :ok <- Application.load(app),
         {:error, :undefined} <- Knigge.Module.fetch_for_app(app) do
      error("Unable to load modules for #{app}, are you sure the app exists?")

      {:error, :unknown_app}
    else
      {:ok, modules} -> {:ok, app, modules}
      other -> other
    end
  end

  defp check_if_implementations_exist({:ok, app, []}) do
    warn("No modules in `#{app}` found which `use Knigge`.")
  end

  defp check_if_implementations_exist({:ok, _app, modules}) do
    Enum.reduce(modules, :ok, fn module, result ->
      module
      |> check_if_implementation_exists()
      |> to_result(result)
    end)
  end

  defp check_if_implementations_exist(other), do: other

  defp check_if_implementation_exists(module) do
    implementation = module.__knigge__(:implementation)

    if Knigge.Module.exists?(implementation) do
      success("Implementation `#{inspect(implementation)}` for `#{inspect(module)}` exists.")
    else
      error("Implementation `#{inspect(implementation)}` for `#{inspect(module)}` is missing!")
    end
  end

  defp to_result(:ok, result), do: result
  defp to_result({:error, _} = error, _result), do: error

  defp exit_with({:error, reason}) when reason in @exit_reasons do
    exit({:shutdown, @exit_codes[reason]})
  end

  defp exit_with({:error, unknown_reason}) do
    error("An unknown error occurred: #{inspect(unknown_reason)}")

    exit({:shutdown, @unknown_error_code})
  end

  defp exit_with(_), do: :ok

  @success_emoji "✅"
  @error_emoji "❌"
  @warn_emoji "❓"

  defp success(message), do: Bunt.puts([@success_emoji, " ", :green, message])
  defp error(message), do: Bunt.warn([@error_emoji, " ", :red, message])
  defp warn(message), do: Bunt.warn([@warn_emoji, " ", :gold, message])
end
