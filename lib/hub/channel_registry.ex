defmodule Hub.ChannelRegistry do
  @moduledoc """
  Keeps track of channel processes with channel names as keys.
  """

  @name __MODULE__

  def child_spec([]) do
    %{
      id: __MODULE__,
      type: :worker,
      start: {__MODULE__, :start_link, []}
    }
  end

  @doc """
  Starts the registry
  """
  @spec start_link() :: {:ok, pid} | {:error, reason :: any}
  def start_link do
    Registry.start_link(keys: :unique, name: @name)
  end

  @doc """
  Registers the channel with the channel_name
  """
  @spec register(String.t()) :: :ok | {:duplicate_key, pid}
  def register(channel_name) do
    @name
    |> Registry.register(channel_name, nil)
    |> case do
      {:ok, _pid} ->
        :ok

      {:error, {:already_registered, pid}} ->
        {:duplicate_key, pid}
    end
  end

  @doc """
  Looks up the given channel name
  """
  @spec lookup(String.t()) :: {:ok, pid} | :not_found
  def lookup(channel_name) do
    @name
    |> Registry.lookup(channel_name)
    |> case do
      [] -> :not_found
      [{pid, nil}] -> {:ok, pid}
    end
  end
end
