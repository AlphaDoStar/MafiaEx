defmodule Mafia.Types do
  @moduledoc """
  마피아 게임에서 사용하는 타입 정의 모듈
  """
  @type id :: String.t()

  @type team :: :mafia | :citizen | :neutral
  @type player :: %{
    id: id(),
    name: String.t(),
    role: String.t(),
    team: team(),
    alive: boolean(),
    targets: [id()]
  }

  @type phase :: :day | :discussion | :vote | :defense | :judgement | :night
  @type game_state :: %{
    id: id(),
    day_count: non_neg_integer(),
    phase: phase(),
    players: %{id() => player()},
    pending_actions: %{atom() => %{actor: id(), target: id()}}
  }

  @type room_state :: %{
    # id: id(),
    name: String.t() | nil,
    host: id(),
    game_started: boolean(),
    members: %{id() => %{name: String.t(), meeting: id() | nil}},
    meetings: %{id() => %{name: String.t(), members: %{id() => boolean()}}}  # mute
  }
end
