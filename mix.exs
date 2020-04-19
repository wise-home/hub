defmodule Hub.Mixfile do
  use Mix.Project

  def project do
    [
      app: :hub,
      version: "0.6.5",
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      description: description(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Hub.Application, []}
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    Hub is a single node PubSub hub with pattern matching subscription.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Wise Home", "Lasse Ebert"],
      links: %{
        github: "https://github.com/wise-home/hub",
        docs: "https://hexdocs.pm/hub/"
      }
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [],
      ignore_warnings: "dialyzer_ignore.exs",
      list_unused_filters: true
    ]
  end
end
