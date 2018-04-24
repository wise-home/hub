defmodule Hub.Mixfile do
  use Mix.Project

  def project do
    [
      app: :hub,
      version: "0.6.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [ignore_warnings: "dialyzer.ignore-warnings"],
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
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:dialyxir, "~> 0.4", only: [:dev, :test]}
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
end
