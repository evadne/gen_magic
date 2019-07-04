defmodule GenMagic.MixProject do
  use Mix.Project

  def project do
    [
      app: :gen_magic,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make] ++ Mix.compilers(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.1", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev], runtime: false},
      {:elixir_make, "~> 0.4", runtime: false}
    ]
  end
end
