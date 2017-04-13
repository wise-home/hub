defmodule Hub.Tracker do
  @moduledoc """
  Phoenix.Tracker implementation
  """

  @behaviour Phoenix.Tracker

  def start_link(opts) do
    opts = Keyword.merge([name: __MODULE__], opts)
    GenServer.start_link(Phoenix.Tracker, [__MODULE__, opts, opts], name: __MODULE__)
  end

  def init(opts) do
    server = Keyword.fetch!(opts, :pubsub_server)
    {:ok, %{pubsub_server: server, node_name: Phoenix.PubSub.node_name(server)}}
  end

  def handle_diff(diff, state) do
    for {topic, {joins, leaves}} <- diff do
      for {key, meta} <- joins do
        msg = {:join, key, meta}
        Phoenix.PubSub.direct_broadcast!(state.node_name, state.pubsub_server, topic, msg)
      end

      for {key, meta} <- leaves do
        msg = {:leave, key, meta}
        Phoenix.PubSub.direct_broadcast!(state.node_name, state.pubsub_server, topic, msg)
      end
    end

    {:ok, state}
  end

  # Wrappers for Tracker functions

  def track(pid, topic, key, meta) do
    Phoenix.Tracker.track(__MODULE__, pid, topic, key, meta)
  end

  def untrack(pid, topic, key) do
    Phoenix.Tracker.untrack(__MODULE__, pid, topic, key)
  end

  def update(pid, topic, key, meta) do
    Phoenix.Tracker.update(__MODULE__, pid, topic, key, meta)
  end

  def list(topic) do
    Phoenix.Tracker.list(__MODULE__, topic)
  end
end
