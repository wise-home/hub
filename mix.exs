defmodule Hub.Mixfile do
  use Mix.Project

  def project do
    [
      app: :hub,
      version: "0.1.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps()
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

      {:credo, "~> 0.5", only: [:dev, :test]}
    ]
  end
end
