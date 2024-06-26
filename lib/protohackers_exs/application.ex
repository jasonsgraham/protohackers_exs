defmodule ProtohackersExs.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ProtohackersExs.EchoServer,
      ProtohackersExs.PrimeTime,
      ProtohackersExs.PriceServer,
      ProtohackersExs.BudgetChat,
      ProtohackersExs.UdpServer,
      ProtohackersExs.MobInMiddle.Supervisor,
      ProtohackersExs.SpeedDaemon.Supervisor
    ]
    opts = [strategy: :one_for_one, name: ProtohackersExs.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
