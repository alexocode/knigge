defmodule Mix.Tasks.Knigge.Verify do
  use Mix.Task

  import Knigge.CLI.Output

  alias Knigge.Verification
  alias Knigge.Verification.Context

  require Context

  @shortdoc "Verify the validity of your facades and their implementations."
  @moduledoc """
  #{@shortdoc}

  At the moment `knigge.verify` "only" ensures that the implementation modules
  of your facades exist. Running the task on a code base with two facades might
  look like this:

      $ mix knigge.verify
      Verify 2 Knigge facades in 'my_app'.

      1/2 Facades passed:
      MyApp.MyGreatFacade -> MyApp.MyGreatImpl

      1/2 Facades failed:
      MyApp.AnotherFacade -> MyApp.AnothrImpl (implementation does not exist)

      Completed in 0.009 seconds.

      Validation failed for 1/2 facades.

  The attentive reader might have noticed that `MyApp.AnothrImpl` contains a
  spelling error: `Anothr` instead of `Another`.

  Catching errors like this is the main responsibility of `knigge.verify`. When
  an issue is detected the task will exit with an error code, which allows you
  to use it in your CI pipeline - for example before you build your production
  release.

  ## Options

  --app (optional):
    Name of the app for which the facades need to be verified.
    Defaults to the current working environment app.
  """

  @exit_codes %{unknown_app: 1, missing_modules: 2, unknown_options: 3}
  @exit_reasons Map.keys(@exit_codes)

  @unknown_error_code 64

  @impl Mix.Task
  def run(raw_args) do
    Mix.Task.run("compile")

    with {:ok, opts} <- parse(raw_args),
         :ok <- do_run(opts) do
      :ok
    else
      {:error, reason} ->
        maybe_print_error(reason)

        exit({:shutdown, to_exit_code(reason)})
    end
  end

  defp parse(raw_args) do
    case OptionParser.parse(raw_args, strict: [app: :string]) do
      {opts, _argv, []} -> {:ok, opts}
      {_parsed, _argv, errors} -> unknown_switches(errors)
    end
  end

  defp unknown_switches(errors) do
    options = Enum.map_join(errors, ", ", &elem(&1, 0))

    {:error, {:unknown_options, "Unknown switch(es) received: " <> options}}
  end

  defp do_run(opts) do
    opts
    |> Keyword.get_lazy(:app, &calling_app/0)
    |> run_for()
  end

  defp calling_app, do: Mix.Project.get().project()[:app]

  defp run_for(app) when is_binary(app) do
    app
    |> String.to_atom()
    |> run_for()
  end

  defp run_for(app) do
    case Context.for_app(app) do
      {:ok, context} ->
        context
        |> begin_verification()
        |> Verification.run()
        |> finish_verification()
        |> to_result_tuple()

      {:error, {:unknown_app, app}} ->
        error("Unable to load modules for #{app || "current app"}, are you sure the app exists?")

        {:error, :unknown_app}

      other ->
        other
    end
  end

  defp begin_verification(%Context{app: app, modules: []} = context) do
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

  defp to_result_tuple(%Context{} = context) do
    if Context.error?(context) do
      {:error, context.error}
    else
      :ok
    end
  end

  defp maybe_print_error(%Context{error: :missing_modules} = context) do
    error("Validation failed for #{length(context.missing)}/#{length(context.modules)} facades.")
  end

  defp maybe_print_error(%Context{}), do: :ok
  defp maybe_print_error({:unknown_switches, message}), do: error(message)

  defp maybe_print_error(unknown_reason) do
    error("An unknown error occurred: #{inspect(unknown_reason)}")
  end

  defp to_exit_code(%Context{error: reason}), do: to_exit_code(reason)
  defp to_exit_code(reason) when reason in @exit_reasons, do: @exit_codes[reason]
  defp to_exit_code(_unknown_reason), do: @unknown_error_code
end
