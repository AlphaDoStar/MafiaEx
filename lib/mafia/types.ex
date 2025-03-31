defmodule Mafia.Types do
  @moduledoc """
  마피아 게임에서 사용되는 공통 타입 정의 모듈
  """
  @type id :: String.t()
  @type team :: :mafia | :citizen | :neutral
  @type player :: %{
    id: id(),
    name: String.t(),
    role: String.t(),
    team: team(),
    alive?: boolean(),
    target_id: id() | nil
  }

  @type night_action :: :death | :protection
  @type night_event :: %{
    action: night_action(),
    target: String.t()
  }

  @type phase :: :day | :discussion | :vote | :defense | :judgement | :night
  @type game_state :: %{
    day_count: non_neg_integer(),
    phase: phase(),
    players: %{id() => player()},
    night_event: night_event() | nil,
    alive_mafia: non_neg_integer(),
    alive_citizen: non_neg_integer()
  }
end
