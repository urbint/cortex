defmodule Cortex.Mixfile do
  use Mix.Project

  def project do
    [app: :cortex,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/urbint/cortex",
     deps: deps(),
     package: package(),
     description: description(),
    ]
  end

  defp description do
    "Cortex is the intelligent coding assistant for Elixir."
  end

  defp package do
    [
     maintainers: ["Russell Matney", "Ryan Schmukler", "Urbint"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/urbint/cortex"}
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger],
     mod: {Cortex.Application, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:exfswatch, "~> 0.4"}
    ]
  end
end
