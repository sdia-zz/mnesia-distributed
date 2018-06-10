defmodule Libkvm.MixProject do
  use Mix.Project

  def project do
    [
      app: :libkvm,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :lbm_kv]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      {:lbm_kv, git: "https://github.com/sdia/lbm_kv", ref: "bb959858a6"},
    ]
  end
end
