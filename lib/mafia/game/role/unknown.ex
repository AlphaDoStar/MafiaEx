defmodule Mafia.Game.Role.Unknown do
  @type id :: String.t()
  @type targets :: %{pos_integer() => id()}
  @type t :: %__MODULE__{
    targets: targets()
  }

  defstruct [:targets]

  @spec new() :: t()
  def new do
    %__MODULE__{
      targets: %{}
    }
  end
end

defimpl Mafia.Game.Role, for: Mafia.Game.Role.Unknown do
  alias Mafia.Game.Role
  alias Mafia.Game.State

  @impl true
  @spec atom(Role.Unknown.t()) :: atom()
  def atom(_), do: :unknown

  @impl true
  @spec team(Role.Unknown.t()) :: Role.team()
  def team(_), do: :neutral

  @impl true
  @spec priority(Role.Unknown.t()) :: non_neg_integer()
  def priority(_), do: 0

  @impl true
  @spec display_name(Role.Unknown.t()) :: String.t()
  def display_name(_), do: "알 수 없음"

  @impl true
  @spec begin_phase(Role.Unknown.t(), State.phase(), State.id(), State.t()) :: State.t()
  def begin_phase(_, _, _, state), do: state

  @impl true
  @spec available_targets(Role.Unknown.t(), State.phase()) :: Role.Unknown.targets()
  def available_targets(_, _), do: %{}

  @impl true
  @spec register_ability(Role.Unknown.t(), State.phase(), State.id(), State.t()) :: {String.t(), State.t()}
  def register_ability(_, _, _, state), do: {"알 수 없음", state}

  @impl true
  @spec resolve_ability(Role.Unknown.t(), State.phase(), State.t()) :: State.t()
  def resolve_ability(_, _, state), do: state
end
