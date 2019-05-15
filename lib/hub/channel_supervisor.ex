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
  # Replace with DynamicSupervisor.on_start_child when this PR is merged and released:
  # https://github.com/elixir-lang/elixir/pull/7590
  @spec start_child(String.t()) :: DynamicSupervisor.on_start_child()
  def start_child(channel_name) do
    DynamicSupervisor.start_child(@name, {Channel, channel_name})
  end
end
