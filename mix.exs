defmodule GenMagic.MixProject do
  use Mix.Project

  def project do
    [
      app: :gen_magic,
      version: "0.1.0",
      elixir: "~> 1.8",
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
      {:elixir_make, "~> 0.4", runtime: false},
      {:exexec, "~> 0.2.0"},
      {:erlexec, "~> 1.10.0"}
    ]
  end
end
