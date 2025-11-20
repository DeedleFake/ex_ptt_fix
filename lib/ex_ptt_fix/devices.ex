defmodule ExPttFix.Devices do
  use GenServer
  require Logger

  alias ExPttFix.Xdo

  @name __MODULE__

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  @impl true
  def init([]) do
    state = %{device_processes: %{}, pressed: MapSet.new()}
    {:ok, state, {:continue, :scan_devices}}
  end

  @impl true
  def handle_continue(:scan_devices, state) do
    devices = InputEvent.enumerate()

    state =
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
  def handle_info(:test, state) do
    InputEvent.stop(state.device_processes["/dev/input/event2"])
    {:noreply, state}
  end

  @impl true
  def handle_info(:scan_devices_tick, state) do
    {:noreply, state, {:continue, :scan_devices}}
  end

  @impl true
  def handle_info({:input_event, path, events}, state) do
    config_key = config_key()
    config_press = config_press()

    state =
      for {:ev_key, key, key_state} <- events,
          key_state in [0, 1],
          key == config_key,
          reduce: state do
        state -> update_pressed(state, config_key, config_press, path, key_state != 0)
      end

    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    state.device_processes
    |> Enum.find(&match?({_, ^pid}, &1))
    |> case do
      {path, ^pid} ->
        {_, state} = pop_in(state.device_processes[path])
        state = update_pressed(state, config_key(), config_press(), path, false)
        {:noreply, state}

      nil ->
        {:noreply, state}
    end
  end

  defp start_device_process(path) do
    spec =
      Supervisor.child_spec(
        {InputEvent, path: path, receiver: @name},
        restart: :transient
      )

    DynamicSupervisor.start_child(ExPttFix.DeviceSupervisor, spec)
  end

  defp update_pressed(state, config_key, config_press, path, key_state) do
    pressed =
      if key_state do
        MapSet.put(state.pressed, path)
      else
        MapSet.delete(state.pressed, path)
      end

    if pressed != state.pressed do
      pressed? = MapSet.size(pressed) != 0
      Logger.debug("#{config_key} pressed: #{pressed?} (#{path})")

      Xdo.keypress(pressed?, config_press)
      %{state | pressed: pressed}
    else
      state
    end
  end

  defp config_key() do
    Application.fetch_env!(:ex_ptt_fix, :key)
    |> String.to_existing_atom()
  end

  defp config_press() do
    Application.fetch_env!(:ex_ptt_fix, :press)
  end
end
