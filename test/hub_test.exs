defmodule HubTest do
  use ExUnit.Case

  alias Hub.ChannelSupervisor

  require Hub

  test "subscribe and publish in same process" do
    Hub.subscribe_quoted("test1", quote(do: {:hello, _name}))
    Hub.publish("test1", {:hello, "World"})
    Hub.publish("test1", {:goodbye, "World"})

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

    Hub.subscribe_quoted("test2", quote(do: {:hello, _name}), pid: child)

    Hub.publish("test2", {:hello, "World"})
    assert_receive({:received, "World"})
  end

  test "subscribe with macro" do
    Hub.subscribe("test3", {:hello, _name})
    Hub.publish("test3", {:hello, "World"})

    assert_receive({:hello, "World"})
  end

  test "subscribe once" do
    Hub.subscribe("test4", {:hello, _name}, count: 1)
    Hub.publish("test4", {:hello, "World"})
    Hub.publish("test4", {:hello, "You"})

    assert_receive({:hello, "World"})
    refute_receive({:hello, "You"})
    assert Hub.subscribers("test4") == []
  end

  test "auto unsubscribe dead processes" do
    me = self()

    child =
      spawn(fn ->
        receive do
          {:hello, name} -> send(me, {:received, name})
        end
      end)

    Hub.subscribe("test5", {:hello, _name}, pid: child)
    Process.exit(child, :kill)

    Hub.publish("test5", {:hello, "World"})
    refute_receive({:received, "World"})
    assert Hub.subscribers("test5") == []
  end

  test "handle double subscription" do
    Hub.subscribe("test6", {:hello, _name_1})
    Hub.subscribe("test6", {:hello, _name_2})
    Hub.publish("test6", {:hello, "World"})

    assert_receive({:hello, "World"})
    assert_receive({:hello, "World"})
  end

  test "can subscribe to same event multiple times" do
    pattern = quote do: {:hello, _name}
    Hub.subscribe_quoted("test7", pattern)
    Hub.subscribe_quoted("test7", pattern)
    Hub.publish("test7", {:hello, "World"})

    assert_receive({:hello, "World"})
    assert_receive({:hello, "World"})

    assert Hub.subscribers("test7") |> length == 2
  end

  test "does not send to wrong channel" do
    Hub.subscribe("1234", {:hello, _name})
    Hub.publish("test8", {:hello, "World"})

    refute_receive({:hello, "World"})
  end

  test "publish returns the number of receivers" do
    Hub.subscribe("test9", {:goodbye, _name})
    assert Hub.publish("test9", {:hello, "World"}) == 0
    assert Hub.publish("test9", {:goodbye, "World"}) == 1
  end

  test "subscribe and publish multiple times from same process" do
    me = self()

    task =
      Task.async(fn ->
        Hub.subscribe("test10", {:hello, _name}, count: 1)
        send(me, :subscribed)

        result =
          receive do
            {:hello, name} -> [name]
          end

        Hub.subscribe("test10", {:hello, _name}, count: 1)
        send(me, :subscribed)

        receive do
          {:hello, name} -> [name | result]
        end
      end)

    receive do
      :subscribed -> :ok
    end

    assert Hub.publish("test10", {:hello, "You"}) == 1

    receive do
      :subscribed -> :ok
    end

    assert Hub.publish("test10", {:hello, "Me"}) == 1

    result = Task.await(task)
    assert result == ~w(Me You)
  end

  test "local variables parts of pattern" do
    name = "World"
    Hub.subscribe("test11", {:hello, ^name}, bind_quoted: [name: name])
    Hub.publish("test11", {:hello, "World"})

    assert_receive({:hello, "World"})
  end

  test "local complex variable" do
    map = %{foo: "bar"}

    Hub.subscribe("test12", %{map: ^map}, bind_quoted: [map: map])
    message = %{map: %{foo: "bar"}, other: "key"}
    Hub.publish("test12", message)

    assert_receive(^message)
  end

  test "pin function call should raise error" do
    assert_raise CompileError, ~r/undefined function fun/, fn ->
      Hub.subscribe("test13", ^fun(var), bind_quoted: [fun: 42])
      Hub.publish("test13", "message")
    end
  end

  test "subscribe with multiple patterns" do
    Hub.subscribe("test14", [{:hello, _name_1}, {:goodbye, _name_2}], multi: true)
    Hub.publish("test14", {:hello, "World"})
    Hub.publish("test14", {:goodbye, "World"})

    assert_receive({:hello, "World"})
    assert_receive({:goodbye, "World"})
  end

  test "subscribe with multiple patterns and count 1" do
    Hub.subscribe("test15", [{:hello, _name_1}, {:goodbye, _name_2}], multi: true, count: 1)
    Hub.publish("test15", {:hello, "World"})
    Hub.publish("test15", {:goodbye, "World"})
    assert_receive({:hello, "World"})
    refute_receive({:goodbye, "World"})
  end

  test "subscribe with multi, but quoted pattern is not an array" do
    result = Hub.subscribe("test16", :not_a_list, multi: true)
    assert result == {:error, "Must subscribe with a list of patterns when using multi: true"}
  end

  test "subscribe, then unsubscribe" do
    {:ok, ref} = Hub.subscribe("test17", {:hello, _name})
    :ok = Hub.unsubscribe(ref)

    Hub.publish("test17", {:hello, "World"})

    refute_receive({:hello, "World"})
    assert Hub.subscribers("test17") == []
  end

  test "multiple subscriptions with count: 1 in process that dies" do
    spawn(fn ->
      {:ok, _ref} = Hub.subscribe("test18", {:hello, _name}, count: 1)
      {:ok, _ref} = Hub.subscribe("test18", {:goodbye, _name})
      Hub.publish("test18", {:hello, "World"})
    end)

    assert Hub.subscribers("test18") == []
  end

  test "unsubscribe with unknown ref" do
    {:ok, {channel, _ref}} = Hub.subscribe("test19", {:hello, _name})
    invalid_ref = make_ref()
    :ok = Hub.unsubscribe({channel, invalid_ref})
  end

  test "unsubscribe with unknown pid" do
    invalid_ref = make_ref()
    pid = spawn(fn -> :ok end)
    :ok = Hub.unsubscribe({pid, invalid_ref})
  end

  test "race condition on publish and auto-unsubscribe" do
    Hub.subscribe("test20", {:hello, _name}, count: 1)

    spawn(fn -> Hub.publish("test20", {:hello, "World"}) end)
    spawn(fn -> Hub.publish("test20", {:hello, "World"}) end)

    assert_receive({:hello, "World"})
    refute_receive({:hello, "World"})
  end

  test "publish to channel without subscribers" do
    count_before = DynamicSupervisor.count_children(ChannelSupervisor)
    assert Hub.publish("publish to channel without subscribers", :hello) == 0
    count_after = DynamicSupervisor.count_children(ChannelSupervisor)

    assert count_before == count_after
  end

  test "subscribe to same channel from two different processes" do
    parent = self()

    process = fn ->
      Hub.subscribe("test21", :hello)

      send(parent, :ready)

      receive do
        :hello -> :ok
      end

      send(parent, :done)
    end

    spawn_link(process)
    spawn_link(process)

    assert_receive(:ready)
    assert_receive(:ready)

    Hub.publish("test21", :hello)

    assert_receive(:done)
    assert_receive(:done)
  end

  test "unsubscribe_and_flush" do
    {:ok, subscription} = Hub.subscribe("test22", :hello)

    # Ensure that this is not flushed, since it does not match :hello
    send(self(), :other_message)

    # This message should be received but flushed
    assert 1 = Hub.publish("test22", :hello)

    Hub.unsubscribe_and_flush(subscription)

    # This message should not be received, since we unsubscribed
    assert 0 = Hub.publish("test22", :hello)

    refute_received :hello
    assert_receive :other_message
  end

  test "unsubscribe_and_flush with multiple patterns" do
    {:ok, subscription} = Hub.subscribe("test23", [:hello, :goodbye], multi: true)
    Hub.publish("test23", :hello)
    Hub.publish("test23", :goodbye)

    Hub.unsubscribe_and_flush(subscription)

    refute_received :hello
    refute_received :goodbye
  end
end
