defmodule Hub do
  @moduledoc """
  Pub-sub hub

  Subscription is done with a pattern.

  Example:

    Hub.subscribe("global", %{count: count} when count > 42)
    Hub.publish("global", %{count: 45, message: "You rock!"})
  """

  alias Hub.Channel
  alias Hub.ChannelRegistry
  alias Hub.ChannelSupervisor

  @doc """
  Get all subscribers from channel
  """
  defdelegate subscribers(channel_name), to: Channel

  @doc """
  Unsubscribes using the reference returned on subscribe
  """
  defdelegate unsubscribe(ref), to: Channel

  @doc """
  Subscribes to the quoted pattern in the given channel_name

  example:

    Hub.subscribe("global", quote do: %{count: count} when count > 42)
  """
  defdelegate subscribe_quoted(channel_name, quoted_pattern, options \\ []), to: Channel

  @doc """
  Convenience macro for subscribing without the need to unquote the pattern.

  example:

    Hub.subscribe("global", %{count: count} when count > 42)
  """
  defmacro subscribe(channel_name, pattern, options \\ []) do
    quote do
      {bind_quoted, options} = unquote(options) |> Keyword.pop(:bind_quoted, [])
      quoted_pattern = unquote(Macro.escape(pattern)) |> Hub.replace_pins(bind_quoted)

      Hub.subscribe_quoted(unquote(channel_name), quoted_pattern, options)
    end
  end

  @doc """
  Publishes the term to all subscribers that matches it
  Returns the number of subscribers that got the message
  """
  @spec publish(String.t(), any) :: non_neg_integer
  def publish(channel_name, term) do
    channel = upsert_channel(channel_name)
    Channel.publish(channel, term)
  end

  @doc false
  def replace_pins(ast, [] = _binding) do
    ast
  end

  def replace_pins(ast, bindings) do
    {ast, _acc} =
      Macro.traverse(
        ast,
        nil,
        fn ast, _acc ->
          ast = traverse_pin(ast, bindings)
          {ast, nil}
        end,
        fn ast, _acc -> {ast, nil} end
      )

    ast
  end

  def traverse_pin({:^, _, [{name, _, atom}]} = term, bindings) when is_atom(atom) do
    case Keyword.fetch(bindings, name) do
      {:ok, value} -> Macro.escape(value)
      :error -> term
    end
  end

  def traverse_pin(ast, _bindings) do
    ast
  end

  defp upsert_channel(channel_name) do
    case ChannelRegistry.lookup(channel_name) do
      {:ok, channel} ->
        channel

      :not_found ->
        {:ok, channel} = ChannelSupervisor.start_child(channel_name)
        channel
    end
  end
end
