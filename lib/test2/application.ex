defmodule Test2.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Test2Web.Telemetry,
      Test2.Repo,
      {Phoenix.PubSub, name: Test2.PubSub},
      # Start Redis connection
      {Redix, name: :redix},
      # Start the streaming supervisor
      Test2.Streaming.Supervisor,
      # Start the Endpoint (http/https)
      Test2Web.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Test2.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Test2Web.Endpoint.config_change(changed, removed)
    :ok
  end
end