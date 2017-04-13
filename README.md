# Hub

A pub-sub hub that builds on top of phoenix_pubsub. Phoenix is not required.

With Hub, a subscription is made with a pattern to match messages.

Example:

```elixir
# In one process:
Hub.subscribe("some_channel", %{name: _, age: age} when age > 42)
receive do
  %{name: name} -> IO.puts("#{name} is older than 42")
end

# In another process:
Hub.publish("some_channel", %{name: "John", age: 48})
```

## Installation

Add `hub` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:hub, "~> 0.1.0"}]
end
```

## How it works and what you should know.

Hub utlizes `Tracker` and `PubSub` of phoenix_pubsub to provide a robust and simple pub-sub hub where processes can
subscribe to messages with an Elixir pattern just like guard clauses.

Behind the scenes the pattern is "decompiled" into an Elixir AST and saved with the subscription. When a message is
published to a channel, the pattern of each subscription is checked against the message and the subscriptions that
match receives the message.

If you have lots of messages and lots of subscribers in the same channel, this is probably not for you, since the
performance cost of pattern matching each message against each subscriber could be a problem.

However, many applications with many published messages can easily split messages into multiple channels based on
application specific criteria. If performance is a concern, having different channels should be used as much as
possible.

## Usage

A subscription is made with a quoted pattern:

```elixir
Hub.subscribe_quoted("My channel", quote(do: {:some, pattern}), pid: self(), count: :infinity)
```

* The `pid` is the process that should receive published messages. Default is `self()`.
* The `count` is how many times a subscription can be triggered before it is auto-unsubscribed. Default is `:infinity`.

A convenience macro, `subscribe`, can be used to avoid the `quote`. Given the default value of the options, the
following is equivalent to the above:

```elixir
require Hub
Hub.subscribe("My channel", {:some, pattern})
```

To publish a message in a channel, call `Hub.publish/2`:

```elixir
Hub.publish("My channel", {:any, "valid", %{elixir: "term"}})
```

## Examples

Subscribe only once to a message:

```elixir
Hub.subscribe("My channel", {:hello, name}, count: 1)
```

`when` is perfectly legal to use in the pattern:

```elixir
Hub.subscribe("My channel", %User{age: age} when age > 42)
```

Subscribe another process:

```elixir
Hub.subscribe("My channel", {:hello, name}, pid: child_pid)
```

Subscribe to all messages in a channel:

```elixir
Hub.subscribe("My channel", _)
```
