defmodule Mafia.Game do
  @moduledoc """
  마피아 게임 상태 관리 API
  """

  def start_link(game_id, [players: _players] = opts) do
    GenServer.start_link(Mafia.Game.Server, opts, name: via_tuple(game_id))
  end

  def stop(game_id) do
    GenServer.stop(via_tuple(game_id))
  end

  def get_state(game_id) do
    GenServer.call(via_tuple(game_id), :get_state)
  end

  def use_ability(game_id, player_id, target_id) do
    GenServer.call(via_tuple(game_id), {:use_ability, player_id, target_id})
  end

  def begin_day(game_id) do
    GenServer.call(via_tuple(game_id), :begin_day)
  end

  def resolve_day(game_id) do
    GenServer.call(via_tuple(game_id), :resolve_day)
  end

  def begin_discussion(game_id) do
    GenServer.call(via_tuple(game_id), :begin_discussion)
  end

  def begin_night(game_id) do
    GenServer.call(via_tuple(game_id), :begin_night)
  end

  def resolve_night(game_id) do
    GenServer.call(via_tuple(game_id), :resolve_night)
  end

  defp via_tuple(game_id) do
    {:via, Registry, {Mafia.Game.Registry, game_id}}
  end
end
