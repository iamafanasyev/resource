defmodule Resource.MixProject do
  use Mix.Project

  @name "Resource"
  @version "0.1.0"
  @description "A common pattern to acquire a resource, perform some action on it and then run a finalizer, regardless of the outcome of the action"
  @repo_url "https://github.com/iamafanasyev/resource"

  def project do
    [
      app: :resource,
      version: @version,
      elixir: "~> 1.0",
      deps: deps(),
      # Hex
      description: @description,
      package: package(),
      # ExDoc
      name: @name,
      source_url: @repo_url,
      docs: docs()
    ]
  end

  defp deps() do
    [
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp docs() do
    [
      main: @name,
      extras: ["README.md"]
    ]
  end

  defp package() do
    [
      maintainers: ["Aleksandr Afanasev"],
      licenses: ["MIT"],
      links: %{"GitHub" => @repo_url}
    ]
  end
end
