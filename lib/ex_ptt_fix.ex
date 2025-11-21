defmodule ExPttFix do
  @moduledoc """
  This is the main supervisor of the system.
  """

  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init([]) do
    children = [
      {DynamicSupervisor, name: ExPttFix.DeviceSupervisor},
      ExPttFix.Devices,
      {FSNotify, name: ExPttFix.FSNNotify, receiver: ExPttFix.Devices, watches: ["/dev/input"]}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
