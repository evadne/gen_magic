defmodule GenMagic.MixProject do
  use Mix.Project

  def project do
    [
      app: :gen_magic,
      version: "0.20.83",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make] ++ Mix.compilers(),
      deps: deps(),
      source_url: "https://github.com/devstopfix/gen_magic"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.3", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev], runtime: false},
      {:elixir_make, "~> 0.4", runtime: false}
    ]
  end
end
