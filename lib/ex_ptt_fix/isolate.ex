defmodule ExPttFix.Isolate do
  @moduledoc """
  This module provides a supervisor that can be used to wrap other
  processes to prevent their parent supervisor from exiting when they
  crash, while still allowing them to be restarted a few times.

  This is useful for the input device monitoring system because a
  crash of one of the monitors is very likely not fatal to the entire
  program, but rather could simply have been caused by the device
  being disconnected. If so, the regular scans for new devices will
  pick it back up when it's plugged back in.
  """
  use Supervisor, restart: :temporary

  @type options() :: [
          name: Supervisor.name(),
          children: [Supervisor.child_spec()],
          strategy: Supervisor.strategy()
        ]

  @doc """
  Starts the supervisor as part of a supervisor tree. The `:children`
  and `:strategy` options _must_ be provided.
  """
  @spec start_link(options()) :: Supervisor.on_start()
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    opts = Keyword.validate!(opts, [:children, :strategy])
    children = Keyword.fetch!(opts, :children)

    Supervisor.init(children, strategy: Keyword.fetch!(opts, :strategy))
  end
end
