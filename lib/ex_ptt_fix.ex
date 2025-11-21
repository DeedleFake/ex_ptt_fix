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
      {FSNotify, name: ExPttFix.FSNotify, watches: ["/dev/input"]},
      ExPttFix.Devices
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
