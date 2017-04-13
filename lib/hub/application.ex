defmodule Hub.Application do
  @moduledoc """
  OTP application for Hub
  """

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Phoenix.PubSub.PG2, [Hub.PubSub, []]),
      worker(Hub.Tracker, [[name: Hub.Tracker, pubsub_server: Hub.PubSub]])
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
