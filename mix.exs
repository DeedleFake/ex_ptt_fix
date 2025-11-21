defmodule ExPttFix.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_ptt_fix,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExPttFix.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:input_event, "~> 1.4"},
      {:fsnotify, "~> 0.1.1"}
    ]
  end
end
