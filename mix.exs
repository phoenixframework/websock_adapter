defmodule WebSockAdapter.MixProject do
  use Mix.Project

  def project do
    [
      app: :websock_adapter,
      version: "0.4.2",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      name: "WebSockAdapter",
      description: "A set of WebSock adapters for common web servers",
      source_url: "https://github.com/mtrudel/websock_adapter",
      package: [
        files: ["lib", "test", "mix.exs", "README*", "LICENSE*"],
        maintainers: ["Mat Trudel"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/mtrudel/websock_adapter"}
      ]
    ]
  end

  def application do
    if Mix.env() == :test do
      [extra_applications: [:cowboy]]
    else
      []
    end
  end

  defp deps do
    [
      {:websock, "~> 0.4.2"},
      {:plug, "~> 1.14.0"},
      {:bandit, "~> 0.5.9", optional: true},
      {:plug_cowboy, "~> 2.6", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp dialyzer do
    [plt_core_path: "priv/plts", plt_file: {:no_warn, "priv/plts/dialyzer.plt"}]
  end
end
