defmodule Hub.Application do
  @moduledoc """
  OTP application for Hub
  """

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      Hub.ChannelSupervisor,
      Hub.ChannelRegistry
    ]

    opts = [strategy: :one_for_one, name: Hub.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
