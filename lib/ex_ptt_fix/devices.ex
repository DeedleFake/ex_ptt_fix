defmodule ExPttFix.Devices do
  use GenServer
  require Logger

  @name __MODULE__

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  @impl true
  def init([]) do
    state = %{device_processes: %{}}
    {:ok, state, {:continue, :scan_devices}}
  end

  @impl true
  def handle_continue(:scan_devices, state) do
    devices = InputEvent.enumerate()

    for {path, %{name: name}} when not is_map_key(state.device_processes, path) <- devices,
        reduce: state do
      state ->
        Logger.debug("found device: #{path} (#{name})")

        start_device_process(path)
        |> case do
          {:ok, pid} ->
            Process.monitor(pid)
            put_in(state.device_processes[path], pid)

          {:error, err} ->
            Logger.warning(
              "failed to start device monitor for #{path}: #{Exception.format(:error, err)}"
            )

            state
        end
    end

    Process.send_after(self(), :scan_devices_tick, :timer.minutes(5))
    {:noreply, state}
  end

  @impl true
  def handle_info(:scan_devices_tick, state) do
    {:noreply, state, {:continue, :scan_devices}}
  end

  @impl true
  def handle_info({:input_event, path, events}, state) do
    for {:ev_key, :key_comma, key_state} <- events, key_state in [0, 1] do
      Logger.debug("comma pressed: #{key_state != 0} (#{path})")
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    state = update_in(state.device_processes, &remove_device_process(&1, pid))
    {:noreply, state}
  end

  defp start_device_process(path) do
    spec =
      Supervisor.child_spec(
        {InputEvent, path: path, receiver: @name},
        restart: :transient
      )

    DynamicSupervisor.start_child(ExPttFix.DeviceSupervisor, spec)
  end

  defp remove_device_process(device_processes, target_pid) do
    for {path, pid} <- device_processes, pid != target_pid, into: %{}, do: {path, pid}
  end
end
