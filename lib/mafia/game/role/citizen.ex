defmodule Mafia.Game.Role.Citizen do
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

defimpl Mafia.Game.Role, for: Mafia.Game.Role.Citizen do
  alias Mafia.Game.Role
  alias Mafia.Game.State

  @impl true
  @spec atom(Role.Citizen.t()) :: atom()
  def atom(_), do: :citizen

  @impl true
  @spec team(Role.Citizen.t()) :: Role.team()
  def team(_), do: :citizen

  @impl true
  @spec priority(Role.Citizen.t()) :: non_neg_integer()
  def priority(_), do: 0

  @impl true
  @spec display_name(Role.Citizen.t()) :: String.t()
  def display_name(_), do: "시민"

  @impl true
  @spec begin_phase(Role.Citizen.t(), State.phase(), State.id(), State.t()) :: State.t()
  def begin_phase(_, _, _, state), do: state

  @impl true
  @spec available_targets(Role.Citizen.t(), State.phase()) :: Role.Citizen.targets()
  def available_targets(_, _), do: %{}

  @impl true
  @spec register_ability(Role.Citizen.t(), State.phase(), State.id(), State.t()) :: {String.t(), State.t()}
  def register_ability(_, _, _, state), do: {"사용할 수 있는 능력이 없습니다.", state}

  @impl true
  @spec resolve_ability(Role.Citizen.t(), State.phase(), State.t()) :: State.t()
  def resolve_ability(_, _, state), do: state
end
