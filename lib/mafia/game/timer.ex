defmodule Mafia.Game.Timer do
  use GenServer
  require Logger

  @type id :: String.t()

  @spec start_link(id()) :: GenServer.on_start()
  def start_link(game_id) do
    GenServer.start_link(__MODULE__, :ok, name: via_tuple(game_id))
  end

  @spec reset(id(), pos_integer()) :: :ok
  def reset(game_id, new_duration) do
    GenServer.cast(via_tuple(game_id), {:reset, new_duration})
  end

  @spec start(id(), %{pos_integer() => function(), required(:main) => function()}) :: :ok
  def start(game_id, callbacks) do
    GenServer.cast(via_tuple(game_id), {:start, callbacks})
  end

  @spec extend(id(), pos_integer()) :: :ok
  def extend(game_id, ms) do
    GenServer.cast(via_tuple(game_id), {:extend, ms})
  end

  @spec reduce(id(), pos_integer()) :: :ok
  def reduce(game_id, ms) do
    GenServer.cast(via_tuple(game_id), {:reduce, ms})
  end

  @spec stop(id()) :: :ok
  def stop(game_id) do
    GenServer.cast(via_tuple(game_id), :stop)
  end

  @spec shutdown(id()) :: :ok
  def shutdown(game_id) do
    GenServer.cast(via_tuple(game_id), :shutdown)
  end

  @spec remaining(id()) :: pos_integer()
  def remaining(game_id) do
    GenServer.call(via_tuple(game_id), :remaining)
  end

  defp via_tuple(game_id) do
    {:via, Registry, {Mafia.Game.Timer.Registry, game_id}}
  end

  @impl true
  def init(:ok) do
    {:ok, initial_state()}
  end

  @impl true
  def handle_cast({:reset, new_duration}, state) do
    cancel_all_timers(state.timer_refs)
    {:noreply, initial_state(new_duration)}
  end

  @impl true
  def handle_cast({:start, callbacks}, state) do
    new_state = state |> start_timer(callbacks)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:extend, ms}, state) when ms > 0 do
    new_state =
      case state.status do
        :running ->
          cancel_all_timers(state.timer_refs)
          elapsed = System.monotonic_time(:millisecond) - state.start_time
          remaining = max(0, state.duration - elapsed) + ms
          %{state | duration: remaining} |> start_timer(state.callbacks)

        _ ->
          %{state | duration: state.duration + ms}
      end
    {:noreply, new_state}
  end
  def handle_cast({:extend, _ms}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast({:reduce, ms}, state) when ms > 0 do
    new_state =
      case state.status do
        :running ->
          cancel_all_timers(state.timer_refs)
          elapsed = System.monotonic_time(:millisecond) - state.start_time
          remaining = max(0, state.duration - elapsed - ms)
          %{state | duration: remaining} |> start_timer(state.callbacks)

        _ ->
          %{state | duration: max(0, state.duration - ms)}
      end
    {:noreply, new_state}
  end
  def handle_cast({:reduce, _ms}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast(:stop, state) do
    if state.status == :running, do: cancel_all_timers(state.timer_refs)
    new_state =  %{state | duration: 0} |> start_timer(state.callbacks)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:shutdown, state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_call(:remaining, _from, %{status: :running} = state) do
    elapsed = System.monotonic_time(:millisecond) - state.start_time
    remaining = max(0, state.duration - elapsed)
    {:reply, remaining, state}
  end
  def handle_call(:remaining, _from, state) do
    {:reply, state.duration, state}
  end

  @impl true
  def handle_info({:timer_expired, :main, callback}, state) do
    Task.start(fn ->
      try do
        callback.()
      rescue
        error ->
          Logger.error("Mafia.Game.Timer callback error: #{Exception.message(error)}")
      end
    end)

    {:noreply, %{state | status: :expired}}
  end

  @impl true
  def handle_info({:timer_expired, :milestone, callback}, state) do
    Task.start(fn ->
      try do
        callback.()
      rescue
        error ->
          Logger.error("Mafia.Game.Timer callback error: #{Exception.message(error)}")
      end
    end)

    {:noreply, state}
  end

  defp initial_state(duration \\ 0) do
    %{
      status: :reset,
      duration: duration,
      start_time: nil,
      callbacks: %{},
      timer_refs: %{}
    }
  end

  defp start_timer(%{duration: duration} = state, callbacks) when duration <= 0 do
    main_callback = Map.get(callbacks, :main, fn -> nil end)
    send(self(), {:timer_expired, :main, main_callback})
    %{state | callbacks: %{}, timer_refs: %{}}
  end
  defp start_timer(state, callbacks) do
    main_callback = Map.get(callbacks, :main, fn -> nil end)
    main_ref = Process.send_after(self(), {:timer_expired, :main, main_callback}, state.duration)

    milestone_callbacks = callbacks |> Map.delete(:main)
    timer_refs = %{main: main_ref} |> start_milestone_timers(milestone_callbacks, state.duration)

    %{state |
      status: :running,
      start_time: System.monotonic_time(:millisecond),
      callbacks: callbacks,
      timer_refs: timer_refs
    }
  end

  defp start_milestone_timers(timer_refs, callbacks, duration) do
    callbacks
    |> Map.to_list()
    |> Enum.reduce(timer_refs, fn {milestone_ms, callback}, acc ->
      case duration - milestone_ms do
        remaining when remaining < 0 -> acc
        remaining ->
          milestone_ref = Process.send_after(self(), {:timer_expired, :milestone, callback}, remaining)
          Map.put(acc, milestone_ms, milestone_ref)
      end
    end)
  end

  defp cancel_all_timers(timer_refs) do
    Enum.each(timer_refs, fn {_key, ref} -> Process.cancel_timer(ref) end)
  end
end
