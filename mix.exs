defmodule Hub.Mixfile do
  use Mix.Project

  def project do
    [
      app: :hub,
      version: "0.2.1",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
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
      {:phoenix_pubsub, "~> 1.0"},

      {:ex_doc, ">= 0.0.0", only: :dev},
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:dialyxir, "~> 0.4", only: [:dev, :test]},
    ]
  end

  defp description do
    """
    Hub is a PubSub hub with pattern matching subscription.

    It builds on top of phoenix_pubsub, but phoenix is not required to use Hub.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Vesta Merkur", "Lasse Ebert"],
      links: %{
        github: "https://github.com/vesta-merkur/hub",
        docs: "https://hexdocs.pm/hub/"
      }
    ]
  end
end
