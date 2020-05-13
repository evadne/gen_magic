defmodule GenMagic.MixProject do
  use Mix.Project

  if :erlang.system_info(:otp_release) < '21' do
    raise "GenMagic requires Erlang/OTP 21 or newer"
  end

  def project do
    [
      app: :gen_magic,
      version: "1.0.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      compilers: [:elixir_make] ++ Mix.compilers(),
      package: package(),
      deps: deps(),
      dialyzer: dialyzer(),
      name: "GenMagic",
      description: "File introspection with libmagic",
      source_url: "https://github.com/evadne/gen_magic",
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp dialyzer do
    [
      plt_add_apps: [:mix, :iex, :ex_unit],
      flags: ~w(error_handling no_opaque race_conditions underspecs unmatched_returns)a,
      ignore_warnings: "dialyzer-ignore-warnings.exs",
      list_unused_filters: true
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.4.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:elixir_make, "~> 0.4", runtime: false},
      {:nimble_pool, "~> 0.1"}
    ]
  end

  defp package do
    [
      files: ~w(lib/gen_magic/* src/*.c Makefile),
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/evadne/packmatic"},
      source_url: "https://github.com/evadne/packmatic"
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end
end
