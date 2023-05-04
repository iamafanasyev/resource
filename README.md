# Resource

[![Elixir CI](https://github.com/iamafanasyev/resource/actions/workflows/elixir.yml/badge.svg)](https://github.com/iamafanasyev/resource/actions/workflows/elixir.yml)

An abstraction that provides a way to manage resources in a safe and deterministic manner.

Inspired by `Bracket` monad, it is used to ensure that resources are properly acquired and released,
even in the presence of exceptions or other errors.

It abstracts three phases:
 * `acquire`: Takes no arguments and returns a value (acquired resource).
 * `use`: Accepts a value of acquired resource type and runs computation atop of it.
 * `release`: Accepts a value of acquired resource type and runs a "releasing procedure" on it.

The key feature of it, is that once `acquire` succeeded, `release` is guaranteed to be called under the hood
(right after `use` phase, no matter what it returns or even diverges).
So the abstraction ensures that the resource is properly acquired and released,
even in the presence of exceptions or other errors.

Elixir's kernel already has similar facility — `Stream.resource/3`.
However, it is biased toward resources of "stream-nature"
***and*** does not have a facility to *compose* resources together
(e.g. when you have to perform computation on two acquired resources).

So ***the main goal*** of the library is to provide non-biased
***and*** composable facility to work with resources in a safe manner.

To achieve the first goal the library provide a wrapper on top of `Stream.resource/3`.
To achieve the second one it utilizes `Bindable.ForComprehension`.
To do so it provides both `Bindable.FlatMap` and `Bindable.Pure` implementations for `Resource` out of the box.
So plug in the library, and you get a way to safely combine resources using for-comprehension:

```elixir
require Bindable.ForComprehension

summation =
  Bindable.ForComprehension.for {
    x <- create(acquire: fn -> IO.puts("Acquire x"); 40 end, release: fn _ -> IO.puts("Release x") end),
    y <- create(acquire: fn -> IO.puts("Acquire y"); 2 end, release: fn _ -> IO.puts("Release y") end)
  } do
    x + y
  end

Resource.use!(summation, fn sum -> IO.puts("Use sum"); {sum} end)
```


## Installation

The package can be installed by adding `resource` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:resource, "~> 0.1.0"}
  ]
end
```

The docs can be found at <https://hexdocs.pm/resource>.

