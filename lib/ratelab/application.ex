defmodule Ratelab.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Ratelab.LimiterSupervisor, nil},
      {Ratelab.TheService, nil}
      # Starts a worker by calling: Ratelab.Worker.start_link(arg)
      # {Ratelab.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ratelab.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
