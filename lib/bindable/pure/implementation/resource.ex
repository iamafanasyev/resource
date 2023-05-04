defimpl Bindable.Pure, for: Resource do
  @spec of(Resource.t(a), a) :: Resource.t(a) when a: var
  def of(%Resource{}, a) do
    Resource.create(acquire: fn -> a end, release: fn _a -> :unit end)
  end
end
