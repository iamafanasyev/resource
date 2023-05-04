defimpl Bindable.FlatMap, for: Resource do
  @spec flat_map(Resource.t(a), (a -> Resource.t(b))) :: Resource.t(b) when a: var, b: var
  def flat_map(%Resource{singleton_stream: external_resource}, f) do
    %Resource{
      singleton_stream:
        Stream.resource(
          fn -> {:acquired_resource, :unit} end,
          fn
            {:acquired_resource, :unit} ->
              {
                external_resource
                |> Stream.map(f)
                |> Stream.flat_map(fn %Resource{singleton_stream: scoped_internal_resource} ->
                  scoped_internal_resource
                end),
                {:release, :unit}
              }

            {:release, :unit} ->
              {:halt, {:release, :unit}}
          end,
          fn {_, :unit} -> :unit end
        )
    }
  end
end
