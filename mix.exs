defmodule SimpleRepo.Mixfile do
  use Mix.Project

  def project do
    version = "1.2.0"
    [app: :simple_repo,
     version: version,
     elixir: "~> 1.5 or ~> 1.6 or ~> 1.7 or ~> 1.8",
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
      {:ecto, "~> 3.0 or ~> 2.1"},
      {:ecto_sql, "~> 3.0", only: :test},
      {:postgrex, "~> 0.14", only: :test},
      {:excoveralls, "~> 0.7.0", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
