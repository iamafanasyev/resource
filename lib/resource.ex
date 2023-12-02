defmodule Resource do
  @moduledoc """
  An abstraction that provides a way to manage resources in a safe and deterministic manner.

  Inspired by `Bracket` monad, it is used to ensure that resources are properly acquired and released,
  even in the presence of exceptions or other errors.

  It abstracts three phases:
   * `acquire`: Takes no arguments and returns a value (acquired resource).
   * `use`: Accepts a value of acquired resource type and runs computation on it.
   * `release`: Accepts a value of acquired resource type and runs a "releasing procedure" on it.

  The key feature of it, is that once `acquire` succeeded, `release` is guaranteed to be called under the hood
  (right after `use` phase, no matter what it returns or even diverges).
  So the abstraction ensures that the resource is properly acquired and released,
  even in the presence of exceptions or other errors.

  Elixir's kernel already has similar facility — `Stream.resource/3`.
  However, it is biased toward resources of "stream-nature"
  (working with singleton streams is cumbersome and requires a lot of ceremonies)
  ***and*** does not have a facility to *compose* resources together
  (e.g. when you have to perform computation on two acquired at the same time resources).

  So ***the main goal*** of the library is to provide non-biased
  ***and*** composable facility to work with resources in a safe manner.

  To achieve the first goal the library provide a wrapper on top of `Stream.resource/3`.
  To achieve the second one it utilizes `Bindable.ForComprehension`.
  To do so it provides both `Bindable.FlatMap` and `Bindable.Pure` implementations for `Resource` out of the box.
  So plug in the library, and you get a way to safely combine resources using for-comprehension:

        iex> import ExUnit.CaptureIO, only: [capture_io: 1]
        ...> import Bindable.ForComprehension, only: [bindable: 1]
        ...> import Resource, only: [create: 1, use!: 2]
        ...>
        ...> summation =
        ...>   bindable for x <- create(acquire: fn -> IO.puts("Acquire x"); 1 end, release: fn _ -> IO.puts("Release x") end),
        ...>                y <- create(acquire: fn -> IO.puts("Acquire y"); 2 end, release: fn _ -> IO.puts("Release y") end),
        ...>                do: x + y
        ...>
        ...> capture_io fn ->
        ...>   assert_raise RuntimeError, "Boom", fn ->
        ...>     use!(summation, fn _sum -> raise "Boom" end)
        ...>   end
        ...> end
        "Acquire x\\nAcquire y\\nRelease y\\nRelease x\\n"

  """

  @typep singleton_stream(_a) :: Enumerable.t()
  @keys [:singleton_stream]
  @enforce_keys @keys
  defstruct @keys

  @typedoc """
  Resource data type.

  Though `:singleton_stream` has to be treated as an implementation details,
  it was selected in favour to `:acquire` and `:release` functions,
  as it would be more secure *in a some sense*, due to Elixir does not have "private properties",
  so in case of explicit `:acquire` and `:release` struct properties,
  one can access `:acquire` function and "forget" to run `:release`.
  """
  @type t(a) :: %__MODULE__{singleton_stream: singleton_stream(a)}

  @typep unit() :: any()

  @doc """
  Resource "data type constructor".
  """
  @spec create(acquire: (() -> a), release: (a -> unit())) :: t(a) when a: var
  def create(_acquire_and_release_phases = [acquire: acquire, release: release]) do
    %__MODULE__{
      singleton_stream:
        Stream.resource(
          fn -> {:acquired_resource, acquire.()} end,
          fn
            {:acquired_resource, acquired_resource} ->
              {[acquired_resource], {:release, acquired_resource}}

            {:release, acquired_resource} ->
              {:halt, {:release, acquired_resource}}
          end,
          fn {:release, acquired_resource} -> release.(acquired_resource) end
        )
    }
  end

  @doc """
  Eagerly runs the provided computation against the resource.

  If the computation raises, it also raises, but resource is properly released.
  """
  @spec use!(t(a), (a -> b)) :: b when a: var, b: var
  def use!(%__MODULE__{singleton_stream: singleton_stream}, _computation = f) do
    singleton_stream
    |> Stream.map(f)
    |> Enum.at(0)
  end
end
