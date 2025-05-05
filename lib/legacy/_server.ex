defmodule Mafia.Game.LegacyServer do
  @moduledoc """
  마피아 게임 상태 관리 서버
  """
  use GenServer

  @impl true
  def init([players: players]) do
    {:ok, %{
      day_count: 1,
      phase: :day,
      players: players,
      alive_mafia: get_alive_mafia(players) |> length(),
      alive_citizen: get_alive_citizen(players) |> length()
    }}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:use_ability, player_id, target_id}, _from, state) do
    new_state = put_in(state, [:players, player_id, :target_id], target_id)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:begin_day, _from, state) do
    new_state = %{state | day_count: state.day_count + 1, phase: :day}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:resolve_day, _from, state) do
    new_state = %{state | night_event: nil}
    {:reply, state, new_state}
  end

  @impl true
  def handle_call(:begin_discussion, _from, state) do
    new_state = %{state | phase: :discussion}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:begin_night, _from, state) do
    new_state = %{state | phase: :night}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:resolve_night, _from, state) do
    new_state = Mafia.AbilityManager.process_night_abilities(state)
    {:reply, :ok, new_state}
  end

  defp get_alive_mafia(players) do
    players
    |> Map.values()
    |> Enum.filter(fn player ->
      player.alive? && player.team == :mafia
    end)
  end

  defp get_alive_citizen(players) do
    players
    |> Map.values()
    |> Enum.filter(fn player ->
      player.alive? && player.team == :citizen
    end)
  end
end
