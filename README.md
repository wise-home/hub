# Hub

A pub-sub hub that builds on top of phoenix_pubsub. Phoenix is not required.

With Hub, a subscription is made with a pattern to match messages.

Example:

```elixir
# In one process:
Hub.subscribe("some_channel", {:hello, name})
receive do
  {:hello, name} -> IO.puts("Hello #{name}")
end

# In another process:
Hub.publish("some_channel", {:hello, "World"})
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `hub` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:hub, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/hub](https://hexdocs.pm/hub).
