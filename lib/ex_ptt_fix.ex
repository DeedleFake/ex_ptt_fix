defmodule ExPttFix do
  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init([]) do
    children = [
      {DynamicSupervisor, name: ExPttFix.DeviceSupervisor},
      ExPttFix.Devices
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
