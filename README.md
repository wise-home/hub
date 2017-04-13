# Hub

A pub-sub hub that builds on top of phoenix_pubsub. Phoenix is not required.

With Hub, a subscription is made with a pattern to match messages.

Example:

```elixir
# In one process:
Hub.subscribe("some_channel", %{name: name, age: age} when age > 42)
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
