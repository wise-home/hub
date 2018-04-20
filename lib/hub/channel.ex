defmodule Hub.Channel do
  @moduledoc """
  GenServer that handles a single channel. This serializes publishes, subscribes and unsubscribes on that channel, and
  makes sure no race condition can occur.
  """

  alias Hub.ChannelRegistry
  alias Hub.Subscriber
  alias Hub.Tracker

  use GenServer

  @type subscribe_options :: [subscribe_option]
  @type subscribe_option :: {:pid, pid} | {:count, count} | {:multi, boolean}
  @type count :: pos_integer | :infinity
  @type pattern :: any

  @subscription_topic "Hub.subscriptions"
  @tracker_topic_prefix "Hub.subscribers."

  # Public API

  @doc """
  Starts the Channel
  """
  @spec start_link(String.t()) :: GenServer.on_start()
  def start_link(channel_name) do
    GenServer.start_link(__MODULE__, channel_name)
  end

  @doc """
  Subscribes with the quoted pattern
  """
  @spec subscribe_quoted(String.t(), any, subscribe_options) :: {:ok, reference} | {:error, reason :: String}
  def subscribe_quoted(channel_name, quoted_pattern, options \\ []) do
    map_options = options |> Enum.into(%{})
    do_subscribe_quoted(channel_name, quoted_pattern, map_options)
  end

  @doc """
  Publishes the message to all matching subscribers of this channel.
  Returns number of subscribers that the message was sent to.
  """
  @spec publish(pid, any) :: non_neg_integer
  def publish(channel, message) do
    GenServer.call(channel, {:publish, message})
  end

  @doc """
  Get all subscribers from channel
  """
  @spec subscribers(String.t()) :: [Subscriber.t()]
  def subscribers(channel_name) do
    channel_name
    |> tracker_topic
    |> Tracker.list()
    |> Enum.map(fn {_key, %{subscriber: subscriber}} -> subscriber end)
  end

  @doc """
  Unsubscribes using the reference returned on subscribe
  """
  @spec unsubscribe(reference) :: :ok
  def unsubscribe(ref) do
    @subscription_topic
    |> Tracker.list()
    |> Enum.find(&match?({^ref, _}, &1))
    |> case do
      nil ->
        :ok

      {^ref, %{subscriber: subscriber}} ->
        :ok = Tracker.untrack(subscriber.pid, tracker_topic(subscriber.channel_name), ref)
        :ok = Tracker.untrack(subscriber.pid, @subscription_topic, ref)
        :ok
    end
  end

  # GenServer callbacks

  def init(channel_name) do
    case ChannelRegistry.register(channel_name) do
      :ok ->
        {:ok, channel_name}

      {:duplicate_key, _pid} ->
        :ignore
    end
  end

  def handle_call({:publish, message}, _from, channel_name) do
    num_subscribers =
      channel_name
      |> subscribers()
      |> Enum.filter(&publish_to_subscriber?(message, &1))
      |> Enum.map(&publish_to_subscriber(message, &1))
      |> length

    {:reply, num_subscribers, channel_name}
  end

  # Helpers

  defp publish_to_subscriber?(term, %{multi: true} = subscriber) do
    subscriber.pattern
    |> Enum.any?(&pattern_match?(&1, term))
  end

  defp publish_to_subscriber?(term, subscriber) do
    pattern_match?(subscriber.pattern, term)
  end

  defp publish_to_subscriber(term, subscriber) do
    update_subscriber(subscriber)
    send(subscriber.pid, term)
  end

  defp update_subscriber(%{count: :infinity}) do
    :ok
  end

  defp update_subscriber(%{count: 1, ref: ref}) do
    unsubscribe(ref)
  end

  defp update_subscriber(%{count: count, pid: pid, channel_name: channel_name} = subscriber) when count > 1 do
    subscriber = %{subscriber | count: count - 1}
    Tracker.update(pid, tracker_topic(channel_name), subscriber.ref, %{subscriber: subscriber})
  end

  defp pattern_match?(pattern, term) do
    quoted_term = Macro.escape(term)

    ast =
      quote do
        case unquote(quoted_term) do
          unquote(pattern) -> true
          _ -> false
        end
      end

    {result, _} = Code.eval_quoted(ast)
    result
  end

  defp tracker_topic(channel_name) when is_binary(channel_name) do
    @tracker_topic_prefix <> channel_name
  end

  defp do_subscribe_quoted(_channel, quoted_pattern, %{multi: true}) when not is_list(quoted_pattern) do
    {:error, "Must subscribe with a list of patterns when using multi: true"}
  end

  defp do_subscribe_quoted(channel_name, quoted_pattern, options) do
    # Try to pattern match to catch syntax errors before publishing
    pattern_match?(quoted_pattern, nil)

    pid = options |> Map.get(:pid, self())
    count = options |> Map.get(:count, :infinity)
    multi = options |> Map.get(:multi, false)

    subscriber = Subscriber.new(channel_name, pid, quoted_pattern, count, multi)

    {:ok, _} = Tracker.track(pid, tracker_topic(channel_name), subscriber.ref, %{subscriber: subscriber})
    {:ok, _} = Tracker.track(pid, @subscription_topic, subscriber.ref, %{subscriber: subscriber})

    {:ok, subscriber.ref}
  end
end
