defmodule ProtohackersExs.EchoServerTest do
  use ExUnit.Case
  test "echos anything back" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5001, [mode: :binary, active: false])
    assert :gen_tcp.send(socket, "foo") == :ok
    assert :gen_tcp.send(socket, "bar") == :ok
    :gen_tcp.shutdown(socket, :write)

    assert :gen_tcp.recv(socket, 0, 5000) == {:ok, "foobar"}

  end

  test "echo sever has max buffer size" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5001, [mode: :binary, active: false])
    assert :gen_tcp.send(socket, :binary.copy("a", 1024 * 100 + 1)) == :ok
    assert :gen_tcp.recv(socket, 0) == {:error, :closed}

  end

end
