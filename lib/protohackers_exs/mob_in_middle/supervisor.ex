defmodule ProtohackersExs.MobInMiddle.Supervisor do

  use Supervisor

  def start_link([]= opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do

    children = [
      {ProtohackersExs.MobInMiddle.ConnectionSupervisor, []},
      {ProtohackersExs.MobInMiddle.Acceptor, opts}
    ]
    Supervisor.init(children, strategy: :rest_for_one)
  end
end
