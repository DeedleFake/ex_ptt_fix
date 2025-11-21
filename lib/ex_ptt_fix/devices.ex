defmodule ExPttFix.Devices do
  @moduledoc """
  This GenServer monitors for new devices being connected and starts
  new processes to monitor each when it finds one. It waits for the
  expected key to be pressed on each and sends the appropriate key to
  the X server when the expected keys are pressed.
  """

  use GenServer
  require Logger

  alias ExPttFix.Xdo

  @name __MODULE__

  def start_link([]) do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  @impl true
  def init([]) do
    FSNotify.subscribe(ExPttFix.FSNotify)
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
          Logger.info("found new device: #{path} (#{name})")

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

    {:noreply, state}
  end

  @impl true
  def handle_info(:test, state) do
    InputEvent.stop(state.device_processes["/dev/input/event2"])
    {:noreply, state}
  end

  @impl true
  def handle_info({:fsnotify_event, _path, op}, state) do
    if :create in op do
      {:noreply, state, {:continue, :scan_devices}}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:input_event, path, events}, state) when is_list(events) do
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
  def handle_info({:input_event, path, :disconnect}, state) do
    state = remove_device(state, path)
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    state.device_processes
    |> Enum.find(&match?({_, ^pid}, &1))
    |> case do
      {path, ^pid} ->
        state = remove_device(state, path)
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

    DynamicSupervisor.start_child(
      ExPttFix.DeviceSupervisor,
      {ExPttFix.Isolate, children: [spec], strategy: :one_for_one}
    )
  end

  defp remove_device(state, path) do
    {pid, state} = pop_in(state.device_processes[path])

    if pid do
      Logger.info("device removed: #{path}")
    end

    update_pressed(state, config_key(), config_press(), path, false)
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
