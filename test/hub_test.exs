defmodule HubTest do
  use ExUnit.Case

  require Hub

  test "subscribe and publish in same process" do
    Hub.subscribe_quoted("global", quote(do: {:hello, name}))
    Hub.publish("global", {:hello, "World"})
    Hub.publish("global", {:goodbye, "World"})

    assert_receive({:hello, "World"})
    refute_receive({:goodbye, "World"})
  end

  test "subscribe and publish in different processes" do
    me = self()

    child =
      spawn_link(fn ->
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

    assert_receive({:hello, "World"})
  end

  test "subscribe once" do
    Hub.subscribe("global", {:hello, name}, count: 1)
    Hub.publish("global", {:hello, "World"})
    Hub.publish("global", {:hello, "You"})

    assert_receive({:hello, "World"})
    refute_receive({:hello, "You"})
    assert Hub.subscribers("global") == []
  end

  test "auto unsubscribe dead processes" do
    me = self()

    child =
      spawn(fn ->
        receive do
          {:hello, name} -> send(me, {:received, name})
        end
      end)

    Hub.subscribe("global", {:hello, name}, pid: child)
    Process.exit(child, :kill)

    Hub.publish("global", {:hello, "World"})
    refute_receive({:received, "World"})
    assert Hub.subscribers("global") == []
  end

  test "handle double subscription" do
    Hub.subscribe("global", {:hello, name_1})
    Hub.subscribe("global", {:hello, name_2})
    Hub.publish("global", {:hello, "World"})

    assert_receive({:hello, "World"})
    assert_receive({:hello, "World"})
  end

  test "can subscribe to same event multiple times" do
    pattern = quote do: {:hello, name}
    Hub.subscribe_quoted("global", pattern)
    Hub.subscribe_quoted("global", pattern)
    Hub.publish("global", {:hello, "World"})

    assert_receive({:hello, "World"})
    assert_receive({:hello, "World"})

    assert Hub.subscribers("global") |> length == 2
  end

  test "does not send to wrong channel" do
    Hub.subscribe("1234", {:hello, name})
    Hub.publish("global", {:hello, "World"})

    refute_receive({:hello, "World"})
  end

  test "publish returns the number of receivers" do
    Hub.subscribe("global", {:goodbye, name})
    assert Hub.publish("global", {:hello, "World"}) == 0

    Hub.subscribe("global", {:hello, name})
    assert Hub.publish("global", {:hello, "World"}) == 1
  end

  test "subscribe and publish multiple times from same process" do
    me = self()

    task =
      Task.async(fn ->
        Hub.subscribe("global", {:hello, name}, count: 1)
        send(me, :subscribed)

        result =
          receive do
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

    assert_receive({:hello, "World"})
  end

  test "local complex variable" do
    map = %{foo: "bar"}

    Hub.subscribe("global", %{map: ^map}, bind_quoted: [map: map])
    message = %{map: %{foo: "bar"}, other: "key"}
    Hub.publish("global", message)

    assert_receive(^message)
  end

  test "pin function call should raise error" do
    assert_raise CompileError, ~r/undefined function fun/, fn ->
      Hub.subscribe("global", ^fun(var), bind_quoted: [fun: 42])
      Hub.publish("global", "message")
    end
  end

  test "subscribe with multiple patterns" do
    Hub.subscribe("global", [{:hello, name}, {:goodbye, name}], multi: true)
    Hub.publish("global", {:hello, "World"})
    Hub.publish("global", {:goodbye, "World"})

    assert_receive({:hello, "World"})
    assert_receive({:goodbye, "World"})
  end

  test "subscribe with multiple patterns and count 1" do
    Hub.subscribe("global", [{:hello, name}, {:goodbye, name}], multi: true, count: 1)
    Hub.publish("global", {:hello, "World"})
    Hub.publish("global", {:goodbye, "World"})
    assert_receive({:hello, "World"})
    refute_receive({:goodbye, "World"})
  end

  test "subscribe with multi, but quoted pattern is not an array" do
    result = Hub.subscribe("global", :not_a_list, multi: true)
    assert result == {:error, "Must subscribe with a list of patterns when using multi: true"}
  end

  test "subscribe, then unsubscribe" do
    {:ok, ref} = Hub.subscribe("global", {:hello, name})
    :ok = Hub.unsubscribe(ref)

    Hub.publish("global", {:hello, "World"})

    refute_receive({:hello, "World"})
    assert Hub.subscribers("global") == []
  end

  test "unsubscribe with unknown ref" do
    {:ok, {channel, _ref}} = Hub.subscribe("global", {:hello, name})
    invalid_ref = make_ref()
    :ok = Hub.unsubscribe({channel, invalid_ref})
  end

  test "unsubscribe with unknown pid" do
    invalid_ref = make_ref()
    pid = spawn(fn -> :ok end)
    :ok = Hub.unsubscribe({pid, invalid_ref})
  end

  test "race condition on publish and auto-unsubscribe" do
    Hub.subscribe("global", {:hello, name}, count: 1)

    spawn(fn -> Hub.publish("global", {:hello, "World"}) end)
    spawn(fn -> Hub.publish("global", {:hello, "World"}) end)

    assert_receive({:hello, "World"})
    refute_receive({:hello, "World"})
  end
end
