defmodule Knigge.MixProject do
  use Mix.Project

  @version "version" |> File.read!() |> String.trim()

  def project do
    [
      app: :knigge,
      version: "0.1.0",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "Knigge",
      source_url: "https://github.com/sascha-wolf/knigge",
      homepage_url: "https://github.com/sascha-wolf/knigge",

      # Hex
      description: description(),
      package: package(),
      version: @version
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # No Runtime
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev], runtime: false},
      {:ex_doc, version(:ex_doc), only: :dev, runtime: false},

      # Test
      {:mox, "~> 0.5", only: :test}
    ]
  end

  defp version(:ex_doc) do
    if Version.match?(System.version(), "< 1.7.0") do
      "~> 0.18.0"
    else
      "~> 0.19"
    end
  end

  #######
  # Hex #
  #######

  def description do
    "An opinionated set of rules to for your behaviours"
  end

  def package do
    [
      files: ["lib", "mix.exs", "LICENSE*", "README*", "version"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/sascha-wolf/knigge"
      },
      maintainers: ["Sascha Wolf <swolf.dev@gmail.com>"]
    ]
  end
end
