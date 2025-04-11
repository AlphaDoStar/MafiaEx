defmodule Mafia.MixProject do
  use Mix.Project

  def project do
    [
      app: :mafia,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
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
      {:elixir_uuid, "~> 1.2.1"}
    ]
  end
end
