defmodule Hub.Channel do
  @moduledoc """
  GenServer that handles a single channel. This serializes publishes, subscribes and unsubscribes on that channel, and
  makes sure no race condition can occur.
  """

  alias Hub.ChannelRegistry
  alias Hub.Subscriber

  use GenServer

  @type subscribe_options :: [subscribe_option]
  @type subscribe_option :: {:pid, pid} | {:count, count} | {:multi, boolean}
  @type count :: pos_integer | :infinity
  @type pattern :: any

  @type subscription_ref :: {pid, reference}

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
  @spec subscribe_quoted(pid, any, subscribe_options) :: {:ok, subscription_ref} | {:error, reason :: String}
  def subscribe_quoted(channel, quoted_pattern, options \\ []) do
    map_options = options |> Enum.into(%{})
    do_subscribe_quoted(channel, quoted_pattern, map_options)
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
  @spec subscribers(pid) :: [Subscriber.t()]
  def subscribers(channel) do
    GenServer.call(channel, :subscribers)
  end

  @doc """
  Unsubscribes using the reference returned on subscribe
  """
  @spec unsubscribe(subscription_ref) :: :ok
  def unsubscribe({channel, ref}) do
    case GenServer.whereis(channel) do
      pid when is_pid(pid) ->
        GenServer.cast(pid, {:unsubscribe, ref})

      nil ->
        :ok
    end
  end

  # GenServer callbacks

  def init(channel_name) do
    case ChannelRegistry.register(channel_name) do
      :ok ->
        state = %{
          # ref => subscriber
          subscriber_by_ref: %{},
          # pid => %{ref => subscriber}
          subscribers_by_pid: %{}
        }

        {:ok, state}

      {:duplicate_key, _pid} ->
        :ignore
    end
  end

  def handle_call({:publish, message}, _from, state) do
    subscribers =
      state.subscriber_by_ref
      |> Map.values()
      |> Enum.filter(&publish_to_subscriber?(message, &1))

    state =
      subscribers
      |> Enum.reduce(state, &publish_to_subscriber(&2, message, &1))

    {:reply, length(subscribers), state}
  end

  def handle_call({:subscribe_quoted, quoted_pattern, options, caller}, _from, state) do
    pid = options |> Map.get(:pid, caller)
    count = options |> Map.get(:count, :infinity)
    multi = options |> Map.get(:multi, false)

    subscriber = Subscriber.new(pid, quoted_pattern, count, multi)
    Process.monitor(pid)

    state = add_subscriber(state, subscriber)

    {:reply, {:ok, {self(), subscriber.ref}}, state}
  end

  def handle_call(:subscribers, _from, state) do
    {:reply, Map.values(state.subscriber_by_ref), state}
  end

  def handle_cast({:unsubscribe, ref}, state) do
    state =
      case Map.fetch(state.subscriber_by_ref, ref) do
        {:ok, subscriber} ->
          remove_subscriber(state, subscriber)

        :error ->
          state
      end

    {:noreply, state}
  end

  def handle_info({:DOWN, _monitor, :process, pid, _reason}, state) do
    state =
      state.subscribers_by_pid
      |> Map.get(pid, %{})
      |> Map.values()
      |> Enum.reduce(state, fn subscriber, state -> remove_subscriber(state, subscriber) end)

    {:noreply, state}
  end

  # Helpers

  defp publish_to_subscriber?(term, %{multi: true} = subscriber) do
    subscriber.pattern
    |> Enum.any?(&pattern_match?(&1, term))
  end

  defp publish_to_subscriber?(term, subscriber) do
    pattern_match?(subscriber.pattern, term)
  end

  defp publish_to_subscriber(state, term, subscriber) do
    state = update_subscriber(state, subscriber)
    send(subscriber.pid, term)
    state
  end

  defp update_subscriber(state, %{count: :infinity}) do
    state
  end

  defp update_subscriber(state, %{count: 1} = subscriber) do
    remove_subscriber(state, subscriber)
  end

  defp update_subscriber(state, %{count: count} = subscriber) when count > 1 do
    new_subscriber = %{subscriber | count: count - 1}

    state
    |> remove_subscriber(subscriber)
    |> add_subscriber(new_subscriber)
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

  defp do_subscribe_quoted(_channel, quoted_pattern, %{multi: true}) when not is_list(quoted_pattern) do
    {:error, "Must subscribe with a list of patterns when using multi: true"}
  end

  defp do_subscribe_quoted(channel, quoted_pattern, options) do
    # Try to pattern match to catch syntax errors before publishing
    pattern_match?(quoted_pattern, nil)

    GenServer.call(channel, {:subscribe_quoted, quoted_pattern, options, self()})
  end

  defp add_subscriber(state, subscriber) do
    %{
      state
      | subscriber_by_ref: Map.put(state.subscriber_by_ref, subscriber.ref, subscriber),
        subscribers_by_pid:
          Map.update(state.subscribers_by_pid, subscriber.pid, %{subscriber.ref => subscriber}, fn subscribers ->
            Map.put(subscribers, subscriber.ref, subscriber)
          end)
    }
  end

  defp remove_subscriber(state, subscriber) do
    %{
      state
      | subscriber_by_ref: Map.delete(state.subscriber_by_ref, subscriber.ref),
        subscribers_by_pid:
          Map.update(state.subscribers_by_pid, subscriber.pid, %{}, fn subscribers ->
            Map.delete(subscribers, subscriber.ref)
          end)
    }
  end
end
