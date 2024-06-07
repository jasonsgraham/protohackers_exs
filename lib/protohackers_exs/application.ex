defmodule ProtohackersExs.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ProtohackersExs.EchoServer,
      ProtohackersExs.PrimeTime,
      ProtohackersExs.PriceServer,
      ProtohackersExs.BudgetChat
    ]
    opts = [strategy: :one_for_one, name: ProtohackersExs.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
