defmodule ExPttFix.Isolate do
  use Supervisor, restart: :temporary

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
