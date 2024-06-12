defmodule ProtohackersExs.SpeedDaemon.Message do
  require Logger
    # Client -> server

    defmodule Plate do
      defstruct [:plate, :timestamp]
    end

    defmodule WantHeartbeat do
      defstruct [:interval]
    end

    defmodule IAmCamera do
      defstruct [:road, :mile, :limit]
    end

    defmodule IAmDispatcher do
      defstruct [:roads]
    end

    # Server -> client

    defmodule Error do
      defstruct [:message]
    end

    defmodule Ticket do
      defstruct [:plate, :road, :mile1, :timestamp1, :mile2, :timestamp2, :speed]
    end

    defmodule Heartbeat do
      defstruct []
    end

    ## Functions

    @type_bytes [0x20, 0x40, 0x80, 0x01, 0x02, 0x04, 0x08]

    ## Decoding

    # Plate
    def decode(<<0x20, plate_size::8, plate::binary-size(plate_size), timestamp::32, rest::binary>>) do
      Logger.debug("Got plate message and rest is #{inspect(rest)}")
      message = %Plate{plate: plate, timestamp: timestamp}
      {:ok, message, rest}
    end

    # WantHeartbeat
    def decode(<<0x40, interval::32, rest::binary>>) do
      {:ok, %WantHeartbeat{interval: interval}, rest}
    end

    # IAmCamera
    def decode(<<0x80, road::16, mile::16, limit::16, rest::binary>>) do
      Logger.debug("Got camera message and rest is #{inspect(rest)}")
      {:ok, %IAmCamera{road: road, mile: mile, limit: limit}, rest}
    end

    # IAmDispatcher
    def decode(<<0x81, numroads::8, roads::size(numroads * 2)-binary, rest::binary>>) do
      Logger.debug("Got dispatcher message and rest is #{inspect(rest)}")
      roads = for <<road::16 <- roads>>, do: road
      {:ok, %IAmDispatcher{roads: roads}, rest}
    end

    # Ticket
    def decode(
          <<0x21, plate_size::8, plate::binary-size(plate_size), road::16, mile1::16,
            timestamp1::32, mile2::16, timestamp2::32, speed::16, rest::binary>>
        ) do
          Logger.debug("Got ticket message and rest is #{inspect(rest)}")
      message = %Ticket{
        plate: plate,
        road: road,
        mile1: mile1,
        timestamp1: timestamp1,
        mile2: mile2,
        timestamp2: timestamp2,
        speed: speed
      }

      {:ok, message, rest}
    end

    def decode(<<0x41, rest::binary>>) do
      {:ok, %Heartbeat{}, rest}
    end

    def decode(<<0x10, size::8, message::size(size)-binary, rest::binary>>) do
      {:ok, %Error{message: message}, rest}
    end

    def decode(<<byte, rest::binary>>) when byte in @type_bytes do
      Logger.debug("Got byte #{inspect(byte)} and rest is #{inspect(rest)}")
      :incomplete
    end

    def decode(<<byte, rest::binary>>) do
      Logger.debug("Got bytes outside of normal types #{inspect(byte)} and rest is #{inspect(rest)}")
      :error
    end

    def decode(<<>>) do
      Logger.debug("Got incomplete message")
      :incomplete
    end

    ## Encoding

    def encode(message)

    def encode(%Error{message: message}) do
      Logger.debug("Encoding Error Message")
      <<0x10, byte_size(message)::8-unsigned-big, message::binary>>
    end

    def encode(%Plate{} = plate) do
      Logger.debug("Encoding Plate Message")
      <<0x20, byte_size(plate.plate)::8, plate.plate::binary, plate.timestamp::32>>
    end

    def encode(%WantHeartbeat{interval: interval}) do
      Logger.debug("Encoding WantHeartbeat Message")
      <<0x40, interval::32>>
    end

    def encode(%IAmCamera{road: road, mile: mile, limit: limit}) do
      Logger.debug("Encoding Camera Message")
      <<0x80, road::16, mile::16, limit::16>>
    end

    def encode(%IAmDispatcher{roads: roads}) do
      Logger.debug("Encoding Dispatch Message")
      encoded_roads = IO.iodata_to_binary(for road <- roads, do: <<road::16>>)
      <<0x81, length(roads)::8, encoded_roads::binary>>
    end

    def encode(%Heartbeat{}) do
      Logger.debug("Encoding Heartbeat Message")
      <<0x41>>
    end

    def encode(%Ticket{} = ticket) do
      Logger.debug("Encoding Ticket Message")
      <<0x21, byte_size(ticket.plate), ticket.plate::binary, ticket.road::16, ticket.mile1::16,
        ticket.timestamp1::32, ticket.mile2::16, ticket.timestamp2::32, ticket.speed::16>>
    end
  end
