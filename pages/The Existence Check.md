# The Existence Check

Before version 1.2.0 `Knigge` used to try to verify at compile time whether the implementation module of a facade exists.
If `Knigge` found the implementation missing it would raise an error.

The idea being that this would catch spelling mistakes and the like **before** releasing the application.
Having a spelling error in delegating to the implementation is **no bueno**: it will crash and burn in a horrible disaster at runtime.

At the time the idea seemed great - and to be honest I still think it does - but reality turned out to be more complicated.

## Knigge VS the Compiler

Sometimes `Knigge` would find the implementing module to be missing even though it was there, no spelling error, no nothing.
Anybody who had the pleasure experiencing this would - very rightfully I must say - wonder what the hell was going on.

As it turns out there is no guarantee about the order in which the Elixir compiler will compile the modules of your project.
While it does ensure that dependencies get resolved - such as specifying a `@behaviour` in your module - it will happily chug along compiling your modules in parallel.

And don't get me wrong, that's a good thing, I like that the compiler does this.
It's a great way to speed up compilation, and proves that there are no weird interdependencies in the order of compilation; but it does lead to a problem with `Knigge`.

You see, sometimes the compiler might start with your implementation module `MyImplementation`.
It would then encounter the `@behaviour MyFacade` line, interrupt compilation of the module and compile `MyFacade`.
In cases like this the existence check works just fine.

In other cases the compiler might start with compiling `MyFacade`.
Finding no dependencies it would happily chug along, resolve `use Knigge` and ... BOOM!
`Knigge` would raise a tantrum because it cannot find `MyImplementation`.

So what can we do about it?

## Introducing `mix knigge.verify`

Instead of doing the existence check at compile time `Knigge` now offers the `knigge.verify` mix task.

By using a `Mix.Task` `Knigge` bypasses the whole compilation conundrum since the task runs after your project was fully compiled.

The task scans your app for all modules which `use Knigge` by checking for a `__knigge__/0` function. If this function is found the task fetches the implementation of the facade using `__knigge__(:implementation)` and then verifies that the returned module actually exists.

After performing this check for all found modules it prints the results and exits with an error code if an implementing module was found missing.

As such you can easily integrate `mix knigge.verify` into your CI pipeline to ensure that all implementations exist before pushing to production.

## Roadmap

In addition to having the `mix knigge.verify` task I would like to create a compiler step which performs the existence check. This could then be added to your project in `mix.exs` under the `compilers` key in your `project` function (similar to how `phoenix` and `gettext` add additional compiler steps).

Furthermore I could imagine adding additional verification steps in the future:

- ensuring the implementation actually implements all necessary callbacks
- somehow integrating with `dialyzer` to check the types of the implementation

But until the necessary research and experiments have been done it's hard to say where the journey will go.
Nevertheless feel free to open issues to discuss potential features at any time.
