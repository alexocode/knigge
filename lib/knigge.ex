defmodule Knigge do
  @moduledoc """
  An opinionated way of dealing with behaviours.

  Opinionated means that it offers an easy way of defining a "facade" for a
  behaviour. This facade then delegates calls to the real implementation, which
  is either given directly to `Knigge` or fetched from the configuration.

  `Knigge` can be `use`d directly in a behaviour, or in a separate module by
  passing the behaviour which should be "facaded" as an option.

  ## Overview

  - [Motivation](#module-motivation)
  - [Examples](#module-examples)
  - [Options](#module-options)
  - [Knigge and Compiler Warnings](#module-knigge-and-compiler-warnings)

  ## Motivation

  `Knigge` was born out of a desire to standardize dealing with behaviours and
  their implementations.

  As great fans of [`mox`](https://github.com/plataformatec/mox) we longed for
  an easy way to swap out implementations from the configuration which lead us
  to introduce a facade pattern, where a module's sole responsibility was
  loading the correct implementation and delegating calls.

  This pattern turned out to be very flexible and useful but required a fair bit
  of boilerplate code. `Knigge` was born out of an attempt to reduce this
  boilerplate to the absolute minimum.

  You can read about our motivation in depth [in our devblog](https://dev.betterdoc.org/elixir/friday_project/behaviour/2019/07/30/how-we-deal-with-behaviours-and-boilerplate.html).

  ## Examples

  Imagine a behaviour looking like this:

      defmodule MyGreatBehaviour do
        @callback my_great_callback(my_argument :: any()) :: any()
      end

  Now imagine you want to delegate calls to this behaviour like this:

      defmodule MyGreatBehaviourFacade do
        @behaviour MyGreatBehaviour

        @implementation Application.fetch_env!(:my_application, __MODULE__)

        defdelegate my_great_callback, to: @implementation
      end

  With this in place you can simply reference the "real implementation" by
  calling functions on your facade:

      MyGreatBehaviourFacade.my_great_callback(:with_some_argument)

  `Knigge` allows you to reduce this boilerplate to the absolute minimum:

      defmodule MyGreatBehaviourFacade do
        use Knigge,
          behaviour: MyGreatBehaviour,
          otp_app: :my_application
      end

  Under the hood this compiles down to the explicit delegation visible on the top.
  In case you don't want to fetch your implementation from the configuration,
  `Knigge` also allows you to explicitely pass the implementation of the
  behaviour with the aptly named key `implementation`:

      defmodule MyGreatBehaviourFacade do
        use Knigge,
          behaviour: MyGreatBehaviour,
          implementation: MyGreatImplementation
      end

  ### `defdefault` - Fallback implementations for optional callbacks

  Now imagine you have a more sophisticated behaviour with some optional callbacks:

      defmodule MySophisticatedBehaviour do
        @callback an_optional_callback() :: any()
        @callback a_required_callback() :: any()

        @optional_callbacks an_optional_callback: 0
      end

  As you would expect `Knigge` delegates calls to this callback as usual. But
  since it's optional this delegation might fail. A common pattern is to check
  if the implementation exports the function in question:

      if function_exported?(MyImplementation, :an_optional_callback, 0) do
        MyImplementation.an_optional_callback()
      else
        :my_fallback_implementation
      end

  `Knigge` offers an easy way to specify these fallback implementations with
  `defdefault`:

      defmodule MySophisticatedFacade do
        use Knigge,
          behaviour: MySophisticatedBehaviour,
          otp_app: :my_application

        defdefault an_optional_callback do
          :my_fallback_implementation
        end
      end

  `Knigge` tries to determine at compile-time if the implementation exports
  the function in question and only uses the default if this is not the case.
  As such `defdefault` incurs no runtime overhead and compiles to a simple `def`.

  Of course `defdefault`s can accept arguments as any usual function:

      defdefault my_optional_callback_with_arguments(first_argument, another_argument) do
        case first_argument do
          # ...
        end
      end


  ## Options

  `Knigge` expects either the `otp_app` key or the `implementation` key. If
  neither is provided an error will be raised at compile time.

  When using the `otp_app` configuration you can also pass `config_key`, which
  results in a call looking like this: `Application.fetch_env!(otp_app, config_key)`.
  `config_key` defaults to `__MODULE__`.

  By default `Knigge` does as much work as possible at compile time. This will
  be fine most of the time. In case you want to swap out the implementation at
  runtime - by calling `Application.put_env/2` - you can force `Knigge` to do all
  delegation at runtime. As you might expect this incurs runtime overhead,
  since the implementing module will have to be loaded for each call.

  If you want to do delegation at runtime simply pass `delegate_at_runtime?: true`
  as option - by default `Knigge` delegates at runtime in your `:test`s.

  For further information about options check the `Knigge.Options` module.

  ## Knigge and the `:test` environment

  To give the maximum amount of flexibility `Knigge` delegates at runtime in your
  `:test` environment and at compile time everywhere else.

  This allows you to easily swap out your behaviour implementation - for example by
  calling `Application.put_env/3` - and it also avoids a bunch of compiler warnings.

  ### Compiler Warnings

  With the default configuration `Knigge` does not generate any compiler warnings.

  In case you change the `delegate_at_runtime?` configuration to anything which
  excludes the `:test` environment you will - most likely - encounter compiler
  warnings like this:

      warning: function MyMock.my_great_callback/1 is undefined (module MyMock is not available)
        lib/my_facade.ex:1

      warning: function MyMock.another_callback/0 is undefined (module MyMock is not available)
        lib/my_facade.ex:1

  This can quickly become quite unnerving. Luckily you can explicitly tell the
  compiler to ignore this module in your `mix.exs` file.

  To disable the check simply add a single line to your `mix.exs`' `project/0` function:

      def project do
        [
          # ...
          xref: [exclude: [MyMock]]
        ]
      end

  Where `MyMock` is the name of your configured module in question.
  """

  @type key :: :behaviour | :implementation | :options

  @spec __using__(Knigge.Options.raw()) :: no_return
  defmacro __using__(options) do
    quote bind_quoted: [options: options] do
      import Knigge.Code, only: [defdefault: 2]

      @before_compile Knigge.Code

      Module.register_attribute(__MODULE__, :__knigge__, accumulate: true)

      options =
        options
        |> Keyword.put_new(:behaviour, __MODULE__)
        |> Keyword.put_new(:config_key, __MODULE__)
        |> Knigge.Options.new()

      behaviour =
        options
        |> Knigge.Behaviour.fetch!()
        |> Knigge.Module.ensure_exists!(options, __ENV__)

      @__knigge__ {:options, options}

      @doc "Access Knigge internal values, such as the implementation being delegated to etc."
      @spec __knigge__(:behaviour) :: module()
      @spec __knigge__(:implementation) :: module()
      @spec __knigge__(:options) :: Knigge.Options.t()

      def __knigge__(:behaviour), do: unquote(behaviour)
      def __knigge__(:options), do: @__knigge__[:options]

      if options.delegate_at_runtime? do
        def __knigge__(:implementation) do
          Knigge.Implementation.fetch!(__knigge__(:options))
        end
      else
        implementation =
          options
          |> Knigge.Implementation.fetch!()
          |> Knigge.Module.ensure_exists!(options, __ENV__)

        def __knigge__(:implementation) do
          unquote(implementation)
        end
      end
    end
  end

  @doc "Access the options passed to Knigge for a module"
  @spec options!(module()) :: Knigge.Options.t()
  def options!(module) do
    cond do
      Module.open?(module) ->
        Module.get_attribute(module, :__knigge__)[:options]

      function_exported?(module, :__knigge__, 1) ->
        module.__knigge__(:options)

      true ->
        raise ArgumentError, "expected a module using Knigge but #{inspect(module)} does not."
    end
  end
end
