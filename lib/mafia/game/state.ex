defmodule Mafia.Game.State do
  @moduledoc """
  Mafia.Game.Server의 상태 구조체
  """
  alias Mafia.Game.Player
  alias Mafia.Room.State

  @type id :: String.t()
  @type phase :: :day | :discussion | :vote | :defense | :judgment | :night
  @type action :: %{priority: pos_integer(), action: atom(), target: id()}
  @type t :: %__MODULE__{
    id: id(),
    day_count: non_neg_integer(),
    phase: phase(),
    players: %{id() => Player.t()},
    settings: State.settings(),
    phase_states: %{
      day: %{},
      discussion: %{
        adjusted_time: %{id() => boolean()}
      },
      vote: %{
        candidates: %{pos_integer() => id()},
        counts: %{id() => pos_integer()},
        voted: %{id() => boolean()},
        result: %{
          counts: [{id(), pos_integer()}],
          tied: boolean()
        }
      },
      defense: %{},
      judgment: %{
        approvals: non_neg_integer(),
        rejections: non_neg_integer(),
        judged: %{id() => boolean()},
      },
      night: %{
        actions: %{atom() => action()}
      }
    }
  }

  @enforce_keys [:id, :players, :settings]
  defstruct [
    :id,
    :players,
    :settings,
    day_count: 0,
    phase: :day,
    phase_states: %{
      day: %{},
      discussion: %{
        adjusted_time: %{}
      },
      vote: %{
        candidates: %{},
        counts: %{},
        voted: %{},
        result: %{
          counts: [],
          tied: false
        }
      },
      defense: %{},
      judgment: %{
        approvals: 0,
        rejections: 0,
        judged: %{}
      },
      night: %{
        actions: %{}
      }
    }
  ]

  def new(id, players, settings) do
    %__MODULE__{id: id, players: players, settings: settings}
  end
end
