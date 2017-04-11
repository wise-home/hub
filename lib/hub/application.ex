defmodule Hub.Application do
  @moduledoc """
  The OTP application for Hub
  """

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Phoenix.PubSub.PG2, [Hub.PubSub, []])
    ]

    opts = [strategy: :one_for_one, name: Hub.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
