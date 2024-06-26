defmodule ProtohackersExs.PriceServer do
  use GenServer

  require Logger

  def start_link([] = _opts) do
    GenServer.start_link(__MODULE__, :no_state)
  end

  defstruct [:listen_socket, :supervisor]
  alias ProtohackersExs.PriceServer.DB

  @impl true
  def init(:no_state) do
    {:ok, supervisor} = Task.Supervisor.start_link(max_children: 100)

    listen_options = [
      mode: :binary,
      active: false,
      reuseaddr: true,
      exit_on_close: false
    ]

    case :gen_tcp.listen(5003, listen_options) do
      {:ok, listen_socket} ->
        Logger.info("Starting Means to an End server on port 5003")
        state = %__MODULE__{listen_socket: listen_socket, supervisor: supervisor}
        {:ok, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(:accept, %__MODULE__{} = state) do
    case :gen_tcp.accept(state.listen_socket) do
      {:ok, socket} ->
        Task.Supervisor.start_child(state.supervisor, fn -> handle_connection(socket) end)
        {:noreply, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  defp handle_connection(socket) do
    case handle_requests(socket, DB.new()) do
      :ok -> :ok
      {:error, reason} -> Logger.error("Failed to recieve data: #{inspect(reason)}")
    end

    :gen_tcp.close(socket)
  end

  defp handle_requests(socket, db) do
    case :gen_tcp.recv(socket, 9, 10_000) do
      {:ok, data} ->
        case handle_request(data, db) do
          {nil, db} ->
            handle_requests(socket, db)

          {response, db} ->
            :gen_tcp.send(socket, response)
            handle_requests(socket, db)

          :error ->
            {:error, :invalid_request}
        end

      {:error, :timeout} ->
        handle_requests(socket, db)

      {:error, :closed} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp handle_request(<<?I, timestamp::32-signed-big, price::32-signed-big>>, db) do
    {nil, DB.add(db, timestamp, price)}
  end

  defp handle_request(<<?Q, mintime::32-signed-big, maxtime::32-signed-big>>, db) do
    avg = DB.query(db, mintime, maxtime)
    {<<avg::32-signed-big>>, db}
  end

  defp handle_request(_other, _db) do
    :error
  end
end
