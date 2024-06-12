defmodule ProtohackersExs.SpeedDaemon.Supervisor do

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do

    registry_opts = [
      name: ProtohackersExs.SpeedDaemon.DispatchersRegistry,
      keys: :duplicate,
      listeners: [ProtohackersExs.SpeedDaemon.CentralTicketDispatcher]
    ]
    children = [
      {Registry, registry_opts},
      {ProtohackersExs.SpeedDaemon.CentralTicketDispatcher, []},
      {ProtohackersExs.SpeedDaemon.ConnectionSupervisor, []},
      {ProtohackersExs.SpeedDaemon.Acceptor, opts}
    ]
    Supervisor.init(children, strategy: :rest_for_one)
  end
end
