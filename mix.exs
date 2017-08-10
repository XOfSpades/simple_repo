defmodule SimpleRepo.Mixfile do
  use Mix.Project

  def project do
    version = "0.1.3"
    [app: :simple_repo,
     version: version,
     elixir: "~> 1.5",
     elixirc_paths: elixirc_paths(Mix.env),
     description: "A wrapper around Ecto to simplify queries",
     package: package(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     test_coverage: [tool: ExCoveralls],
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:prod), do: ["lib"]
  defp elixirc_paths(_),     do: ["lib",  "test/support"]

  defp package do
    [
      maintainers: ["Bernhard Støcker"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/xofspades/simple_repo"}
    ]
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
      {:postgrex, "~> 0.13"},
      {:ecto, "~> 2.1"},
      {:excoveralls, "~> 0.6.3", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
