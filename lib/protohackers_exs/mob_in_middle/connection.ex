defmodule ProtohackersExs.MobInMiddle.Connection do
  require Logger
  use GenServer

  def start_link(socket) do
    GenServer.start_link(__MODULE__, socket)
  end

  defstruct [:in_socket, :out_socket]

  @impl true
  def init(in_socket) do
    case :gen_tcp.connect(~c"chat.protohackers.com", 16963, [:binary, active: :once]) do
      {:ok, out_socket} ->
        Logger.debug("Started Connection Handler")
        {:ok, %__MODULE__{in_socket: in_socket, out_socket: out_socket}}

        {:error, reason} ->
          Logger.error("Failed to connect to the upstream server: #{inspect(reason)}")
          {:stop, reason}

    end
  end

  @impl true
  def handle_info(message, state)

  def handle_info(
        {:tcp, in_socket, data},
        %__MODULE__{in_socket: in_socket} = state
      ) do
    :ok = :inet.setopts(in_socket, active: :once)
    Logger.debug("Received data: #{inspect(data)}")
    data = ProtohackersExs.MobInMiddle.Boguscoin.rewrite_addresses(data)
    :gen_tcp.send(state.out_socket, data)
    {:noreply, state}
  end

  def handle_info(
        {:tcp, out_socket, data},
        %__MODULE__{out_socket: out_socket} = state
      ) do
    :ok = :inet.setopts(out_socket, active: :once)
    Logger.debug("Received data: #{inspect(data)}")
    data = ProtohackersExs.MobInMiddle.Boguscoin.rewrite_addresses(data)
    :gen_tcp.send(state.in_socket, data)
    {:noreply, state}
  end

  def handle_info({:tcp_error, socket, reason}, %__MODULE__{} = state)
      when socket in [state.in_socket, state.out_socket] do
    Logger.error("Received TCP error: #{inspect(reason)}")
    :gen_tcp.close(state.in_socket)
    :gen_tcp.close(state.out_socket)
    {:stop, :normal, state}
  end

  def handle_info({:tcp_closed, socket}, %__MODULE__{} = state)
      when socket in [state.in_socket, state.out_socket] do
    Logger.debug("TCP connection closed")
    :gen_tcp.close(state.in_socket)
    :gen_tcp.close(state.out_socket)
    {:stop, :normal, state}
  end

end
