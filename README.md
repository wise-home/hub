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
  [{:hub, "~> 0.3"}]
end
```

## Status

[![CircleCI](https://circleci.com/gh/vesta-merkur/hub.svg?style=svg)](https://circleci.com/gh/vesta-merkur/hub)

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
Hub.subscribe_quoted("My channel", quote(do: {:some, pattern}))
```

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

When a message is published to the pid of a subscription, it is send directly and unmodified to that process' mailbox.
The subscriber should `receive` the message:

```elixir
Hub.subscribe("Channel", {:hello, name})
Hub.subscribe("Channel", {:goodbye, name})

receive do
  {:hello, name} -> IO.puts("Hello #{name}")
  {:goodbye, name} -> IO.puts("Goodbye #{name}")
end
```

If the receiver is a GenServer, and you don't want a blocking `receive`, use `handle_info` instead:

```elixir
def handle_info({:hello, name}, state) do
  IO.puts("Hello #{name}")
  {:noreply, state}
end
```

### Subscribe options

`subscribe` and `subscribe_quoted` accepts these options:

* `pid` (default `self()`) is the process that should receive published messages.
* `count` (default `:infinity`) is how many times a subscription can be triggered before it is auto-unsubscribed.
* `multi` (default `false`). When `true`, the `pattern` argument must be a list of multiple patterns. This is handy if
  combined with `count`.

### Using local variables

Sometimes one wish to subscribe using a pattern involving local variables.
The `subscribe` macro accepts a `bind_quoted` argument, that will replace pinned variables with the given values.

E.g.

```elixir
size = 42
Hub.subscribe("my channel", %{size: ^size}, bind_quoted: [size: size])
```

is equivalent to

```elixir
Hub.subscribe("my channel", %{size: 42})
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

Subscribe to the first message that matches one of the patterns:

```elixir
Hub.subscribe("My channel", [{:hello, name}, {:goodbye, name}], multi: true, count: 1)
```

## Contributing

Tests are run with `mix test`. When submitting new code, make sure `mix credo` also passes.
