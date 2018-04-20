defmodule Hub.ChannelSupervisor do
  @moduledoc """
  Dynamic supervisor for Channel processes
  """

  alias Hub.Channel

  def child_spec([]) do
    %{
      id: __MODULE__,
      type: :supervisor,
      start: {__MODULE__, :start_link, []}
    }
  end

  @name __MODULE__

  @doc """
  Starts the supervisor
  """
  @spec start_link() :: Supervisor.on_start()
  def start_link() do
    DynamicSupervisor.start_link(strategy: :one_for_one, name: @name)
  end

  @doc """
  Starts a Channel worker with the given channel name
  """
  @spec start_child(String.t()) :: Supervisor.on_start_child()
  def start_child(channel_name) do
    DynamicSupervisor.start_child(@name, {Channel, channel_name})
  end
end
