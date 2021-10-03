# Knigge
[![CI](https://github.com/sascha-wolf/knigge/workflows/CI/badge.svg)](https://github.com/sascha-wolf/knigge/actions?query=branch%3Amain+workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/github/sascha-wolf/knigge/badge.svg?branch=main)](https://coveralls.io/github/sascha-wolf/knigge?branch=main)
[![Hexdocs.pm](https://img.shields.io/badge/hexdocs-online-blue)](https://hexdocs.pm/knigge/)
[![Hex.pm](https://img.shields.io/hexpm/v/knigge.svg)](https://hex.pm/packages/knigge)
[![Hex.pm Downloads](https://img.shields.io/hexpm/dt/knigge)](https://hex.pm/packages/knigge)
[![Featured - ElixirRadar](https://img.shields.io/badge/featured-ElixirRadar-543A56)](https://app.rdstation.com.br/mail/0ddee1c8-2ce9-405b-b95f-09c883099090?utm_campaign=elixir_radar_202&utm_medium=email&utm_source=RD+Station)
[![Featured - ElixirWeekly](https://img.shields.io/badge/featured-ElixirWeekly-875DB0)](https://elixirweekly.net/issues/161)

*Sponsored by*  
[![BetterDoc](betterdoc.png)](https://www.betterdoc.org/)

An opinionated way of dealing with behaviours.

Opinionated means that it offers an easy way of defining a "facade" for a
behaviour. This facade then delegates calls to the real implementation, which
is either given directly to `Knigge` or fetched from the configuration.

`Knigge` can be `use`d directly in a behaviour, or in a separate module by
passing the behaviour which should be "facaded" as an option.

[See the documentation](https://hexdocs.pm/knigge) for more information.

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Installation](#installation)
- [Contributing](#contributing)
- [Motivation](#motivation)
- [Examples](#examples)
  - [Without Knigge](#without-knigge)
  - [Using Knigge to reduce boilerplate](#using-knigge-to-reduce-boilerplate)
    - [Specifying a `default` implementation](#specifying-a-default-implementation)
    - [The `behaviour` key is optional](#the-behaviour-key-is-optional)
    - [Specifying the `implementation` directly](#specifying-the-implementation-directly)
  - [`defdefault` - Fallback implementations for optional callbacks](#defdefault---fallback-implementations-for-optional-callbacks)
- [Options](#options)
- [Verifying your implementations - `mix knigge.verify`](#verifying-your-implementations---mix-kniggeverify)
- [Knigge and the `:test` environment](#knigge-and-the-test-environment)
  - [Compiler Warnings](#compiler-warnings)

## Installation

Simply add `knigge` to your list of dependencies in your `mix.exs`:

```elixir
def deps do
  [
    {:knigge, "~> 1.4"}
  ]
end
```

Differences between the versions are explained in [the Changelog](./CHANGELOG.md).

## Contributing

Contributions are always welcome but please read [our contribution guidelines](./CONTRIBUTING.md) before doing so.

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

You can read about our motivation in depth [in our devblog](https://dev.betterdoc.org/elixir/friday_project/behaviour/2019/07/30/how-we-deal-with-behaviours-and-boilerplate.html), which was also featured in [Elixir Radar](https://app.rdstation.com.br/mail/0ddee1c8-2ce9-405b-b95f-09c883099090?utm_campaign=elixir_radar_202&utm_medium=email&utm_source=RD+Station) and [ElixirWeekly](https://elixirweekly.net/issues/161)

## Examples

### Without Knigge

Imagine a behaviour looking like this:

```elixir
defmodule MyGreatBehaviour do
  @callback my_great_callback(my_argument :: any()) :: any()
end
```

Now imagine you want to delegate calls to this behaviour like this:

```elixir
defmodule MyGreatBehaviourFacade do
  @behaviour MyGreatBehaviour

  @implementation Application.fetch_env!(:my_application, __MODULE__)

  defdelegate my_great_callback, to: @implementation
end
```

With this in place you can reference the "real implementation" by calling
functions on your facade:

```elixir
MyGreatBehaviourFacade.my_great_callback(:with_some_argument)
```

### Using Knigge to reduce boilerplate

`Knigge` allows you to reduce this boilerplate to the absolute minimum:

```elixir
defmodule MyGreatBehaviourFacade do
  use Knigge,
    behaviour: MyGreatBehaviour,
    otp_app: :my_application
end
```

#### Specifying a `default` implementation

It's also possible to provide a default implementation:

```elixir
defmodule MyGreatBehaviourFacade do
  use Knigge,
    behaviour: MyGreatBehaviour,
    otp_app: :my_application,
    default: MyDefaultImplementation
end
```

Compared to the "boilerplate" version above, it's as if you'd written:

```elixir
  @implementation Application.get_env(:my_application, __MODULE__, MyDefaultImplementation)
```

instead of:

```elixir
  @implementation Application.fetch_env!(:my_application, __MODULE__)
```

#### The `behaviour` key is optional

Technically even passing the `behaviour` is optional, it defaults to
the current `__MODULE__`. This means that the example from above could
be shortened even more to:

```elixir
defmodule MyGreatBehaviour do
  use Knigge, otp_app: :my_application

  @callback my_great_callback(my_argument :: any()) :: any()
end
```

Under the hood this compiles down to the explicit delegation visible on the top.

#### Specifying the `implementation` directly

In case you don't want to fetch your implementation from the configuration,
`Knigge` also allows you to explicitly pass the implementation of the
behaviour with the aptly named key `implementation`:

```elixir
defmodule MyGreatBehaviourFacade do
  use Knigge,
    behaviour: MyGreatBehaviour,
    implementation: MyGreatImplementation
end
```

### `defdefault` - Fallback implementations for optional callbacks

Now imagine you have a more sophisticated behaviour with some optional callbacks:

```elixir
defmodule MySophisticatedBehaviour do
  @callback an_optional_callback() :: any()
  @callback a_required_callback() :: any()

  @optional_callbacks an_optional_callback: 0
end
```

As you would expect `Knigge` delegates calls to this callback as usual. But
since it's optional this delegation might fail. A common pattern is to check
if the implementation exports the function in question:

```elixir
if function_exported?(MyImplementation, :an_optional_callback, 0) do
  MyImplementation.an_optional_callback()
else
  :my_fallback_implementation
end
```

`Knigge` offers an easy way to specify these fallback implementations with
`defdefault`:

```elixir
defmodule MySophisticatedFacade do
  use Knigge,
    behaviour: MySophisticatedBehaviour,
    otp_app: :my_application

  defdefault an_optional_callback do
    :my_fallback_implementation
  end
end
```

`Knigge` tries to determine at compile-time if the implementation exports
the function in question and only uses the default if this is not the case.
As such `defdefault` incurs no runtime overhead and compiles to a simple `def`.

Of course `defdefault`s can accept arguments as any usual function:

```elixir
defdefault my_optional_callback_with_arguments(first_argument, another_argument) do
  case first_argument do
    # ...
  end
end
```

## Options

`Knigge` expects either the `otp_app` key or the `implementation` key. If
neither is provided an error will be raised at compile time.

When using the `otp_app` configuration you can also pass `config_key`, which
results in a call looking like this: `Application.fetch_env!(otp_app, config_key)`.
`config_key` defaults to `__MODULE__`.

By default `Knigge` does as much work as possible at compile time. This will
be fine most of the time. In case you want to swap out the implementation at
runtime - by calling `Application.put_env/3` - you can force `Knigge` to do all
delegation at runtime. As you might expect this incurs runtime overhead,
since the implementing module will have to be loaded for each call.

If you want to do delegation at runtime simply pass `delegate_at_runtime?: true`
as option - by default `Knigge` delegates at runtime in your `:test`s.

For further information about options check the [`Knigge.Options` module](https://hexdocs.pm/knigge/Knigge.Options.html).

## Verifying your implementations - `mix knigge.verify`

Before version 1.2.0 `Knigge` tried to check at compile time if the implementation of your facade existed.
Due to the way the Elixir compiler goes about compiling your modules this didn't work as expected - [checkout this page if you're interested in the details](https://hexdocs.pm/knigge/the-existence-check.html).

As an alternative `Knigge` now offers the `mix knigge.verify` task which verifies that the implementation modules of your facades actually exist.
The task returns with an error code when an implementation is missing, which allows you to plug it into your CI pipeline - for example as `MIX_ENV=prod mix knigge.verify`.

For details check the documentation of `mix knigge.verify` by running `mix help knigge.verify`.

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

```text
warning: function MyMock.my_great_callback/1 is undefined (module MyMock is not available)
  lib/my_facade.ex:1

warning: function MyMock.another_callback/0 is undefined (module MyMock is not available)
  lib/my_facade.ex:1
```

This can quickly become quite unnerving. Luckily you can explicitly tell the
compiler to ignore this module in your `mix.exs` file.

To disable the check simply add a single line to your `mix.exs`' `project/0` function:

```elixir
def project do
  [
    # ...
    xref: [exclude: [MyMock]]
  ]
end
```

Where `MyMock` is the name of your configured module in question.
