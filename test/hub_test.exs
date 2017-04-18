defmodule HubTest do
  use ExUnit.Case

  require Hub

  test "subscribe and publish in same process" do
    Hub.subscribe_quoted("global", quote do: {:hello, name})
    Hub.publish("global", {:hello, "World"})
    Hub.publish("global", {:goodbye, "World"})

    assert_received({:hello, "World"})
    refute_received({:goodbye, "World"})
  end

  test "subscribe and publish in different processes" do
    me = self()

    child = spawn_link(fn ->
      receive do
        {:hello, name} -> send(me, {:received, name})
      end
    end)
    Hub.subscribe_quoted("global", quote(do: {:hello, name}), pid: child)

    Hub.publish("global", {:hello, "World"})
    assert_receive({:received, "World"})
  end

  test "subscribe with macro" do
    Hub.subscribe("global", {:hello, name})
    Hub.publish("global", {:hello, "World"})

    assert_received({:hello, "World"})
  end

  test "subscribe once" do
    Hub.subscribe("global", {:hello, name}, count: 1)
    Hub.publish("global", {:hello, "World"})
    Hub.publish("global", {:hello, "You"})

    assert_received({:hello, "World"})
    refute_received({:hello, "You"})
    assert Hub.subscribers("global") == []
  end

  test "auto unsubscribe dead processes" do
    me = self()

    child = spawn(fn ->
      receive do
        {:hello, name} -> send(me, {:received, name})
      end
    end)
    Hub.subscribe("global", {:hello, name}, pid: child)
    Process.exit(child, :kill)

    Hub.publish("global", {:hello, "World"})
    refute_received({:received, "World"})
    assert Hub.subscribers("global") == []
  end

  test "handle double subscription" do
    Hub.subscribe("global", {:hello, name_1})
    Hub.subscribe("global", {:hello, name_2})
    Hub.publish("global", {:hello, "World"})

    assert_received({:hello, "World"})
    assert_received({:hello, "World"})
  end

  test "handle duplicate keys" do
    pattern = quote do: {:hello, name}
    Hub.subscribe_quoted("global", pattern)
    Hub.subscribe_quoted("global", pattern)
    Hub.publish("global", {:hello, "World"})

    assert_received({:hello, "World"})
    refute_received({:hello, "World"})

    assert Hub.subscribers("global") |> length == 1
  end

  test "does not send to wrong channel" do
    Hub.subscribe("1234", {:hello, name})
    Hub.publish("global", {:hello, "World"})

    refute_received({:hello, "World"})
  end

  test "publish returns the number of receivers" do
    Hub.subscribe("global", {:goodbye, name})
    assert Hub.publish("global", {:hello, "World"}) == 0

    Hub.subscribe("global", {:hello, name})
    assert Hub.publish("global", {:hello, "World"}) == 1
  end

  test "subscribe and publish multiple times from same process" do
    me = self()
    task = Task.async(fn ->
      Hub.subscribe("global", {:hello, name}, count: 1)
      send(me, :subscribed)
      result = receive do
        {:hello, name} -> [name]
      end

      Hub.subscribe("global", {:hello, name}, count: 1)
      send(me, :subscribed)
      receive do
        {:hello, name} -> [name | result]
      end
    end)

    receive do
      :subscribed -> :ok
    end
    assert Hub.publish("global", {:hello, "You"}) == 1

    receive do
      :subscribed -> :ok
    end
    assert Hub.publish("global", {:hello, "Me"}) == 1

    result = Task.await(task)
    assert result == ~w(Me You)
  end

  test "local variables parts of pattern" do
    name = "World"
    Hub.subscribe("global", {:hello, ^name}, bind_quoted: [name: name])
    Hub.publish("global", {:hello, "World"})

    assert_received({:hello, "World"})
  end

  test "local complex variable" do
    map = %{foo: "bar"}

    Hub.subscribe("global", %{map: ^map}, bind_quoted: [map: map])
    message = %{map: %{foo: "bar"}, other: "key"}
    Hub.publish("global", message)

    assert_received(^message)
  end

  test "pin inside complex term" do
    Hub.subscribe("channel", (fn x -> ^x end).(1), bind_quoted: [x: 5])
    [subscriber] = Hub.subscribers("channel")

    assert subscriber.pattern |> Macro.to_string == "(fn x -> 5 end).(1)"
  end

  test "pin function call should raise error" do
    assert_raise CompileError, ~r/undefined function fun/, fn ->
      Hub.subscribe("global", ^fun(var), bind_quoted: [fun: 42])
      Hub.publish("global", "message")
    end
  end
end
