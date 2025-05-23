defmodule Mafia.Game.State do
  @moduledoc """
  Mafia.Game.Server의 상태 구조체
  """
  alias Mafia.Game.Player
  alias Mafia.Room.State

  @type id :: String.t()
  @type phase :: :day | :discussion | :vote | :defense | :judgment | :night
  @type players :: %{id() => Player.t()}
  @type t :: %__MODULE__{
    id: id(),
    day_count: non_neg_integer(),
    phase: phase(),
    players: players(),
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
          counts: [{Player.t(), pos_integer()}],
          tied: boolean()
        }
      },
      defense: %{},
      judgment: %{
        approval: non_neg_integer(),
        rejection: non_neg_integer(),
        judged: %{id() => boolean()}
      },
      night: %{
        targets: %{module() => id()},
        result: %{
          message: String.t()
        }
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
        approval: 0,
        rejection: 0,
        judged: %{}
      },
      night: %{
        targets: %{},
        result: %{
          message: nil
        }
      }
    }
  ]

  @behaviour Access

  @impl true
  def fetch(struct, key), do:  Map.fetch(struct, key)

  @impl true
  def get_and_update(struct, key, fun), do: Map.get_and_update(struct, key, fun)

  @impl true
  def pop(struct, key), do: Map.pop(struct, key)

  @spec new(id(), players(), State.settings()) :: t()
  def new(id, players, settings) do
    %__MODULE__{id: id, players: players, settings: settings}
  end
end
