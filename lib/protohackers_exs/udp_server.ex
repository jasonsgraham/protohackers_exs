defmodule ProtohackersExs.UdpServer do
  use GenServer

  require Logger

  def start_link([] = _opts) do
    GenServer.start_link(__MODULE__, :no_state)
  end

  defstruct [:socket, store: %{"version" => "KV 1.0"}]

  @impl true
  def init(:no_state) do
    Logger.info("Starting UDP server on port 5005")

    case :gen_udp.open(5005, [:binary, active: false, recbuf: 1000]) do
      {:ok, socket} ->
        state = %__MODULE__{socket: socket}
        {:ok, state, {:continue, :recv}}

      {:error, reason} ->
        {:stop, reason}
    end

  end

  @impl true
  def handle_continue(:recv, %__MODULE__{} = state) do
    case :gen_udp.recv(state.socket, 0) do
      {:ok, {address, port, packet}} ->
        Logger.info("Received UDP packet from #{inspect(address)}:#{inspect(port)}: #{inspect(packet)}}")
      state =
        case String.split(packet, "=", parts: 2) do

          ["version", _value] ->
            state

          [key, value] ->
            Logger.debug("Insert key #{key} with value #{inspect(value)}")
            put_in(state.store[key], value)

          [key] ->
            Logger.debug("Requested key: #{inspect(key)}")
            packet = "#{key}=#{state.store[key]}"
            :gen_udp.send(state.socket, address, port, packet)
            state
        end

      {:noreply, state, {:continue, :recv}}

    {:error, reason} ->
      {:stop, reason}
    end
  end

end
