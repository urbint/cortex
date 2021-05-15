defmodule Cortex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cortex,
      version: "0.6.0",
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      source_url: "https://github.com/urbint/cortex",
      deps: deps(),
      package: package(),
      description: description(),
      dialyzer: [ignore_warnings: "./.dialyzer-ignore-warnings.txt"],
      elixirc_paths: elixir_paths(Mix.env()),
      xref: [exclude: [IEx.Helpers]]
    ]
  end

  defp description do
    "Cortex is the intelligent coding assistant for Elixir."
  end

  defp package do
    [
      maintainers: [
        "Russell Matney",
        "Ryan Schmukler",
        "William Carroll",
        "Justin DeMaris",
        "Griffin Smith",
        "Cameron Kingsbury",
        "Urbint"
      ],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/urbint/cortex"}
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger], mod: {Cortex.Application, []}]
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
      {:file_system, "~> 0.2"},
      {:credo, "~> 0.9", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:ex_dash, "~> 0.1.0", only: [:dev]}
    ]
  end

  def elixir_paths(:test), do: ["lib", "test/fixtures/initials"]
  def elixir_paths(_), do: ["lib"]
end
