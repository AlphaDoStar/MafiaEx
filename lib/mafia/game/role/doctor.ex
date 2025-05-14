defmodule Mafia.Game.Role.Doctor do
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

defimpl Mafia.Game.Role, for: Mafia.Game.Role.Doctor do
  alias Mafia.Game.Role
  alias Mafia.Game.State

  @impl true
  @spec atom(Role.Doctor.t()) :: atom()
  def atom(_), do: :doctor

  @impl true
  @spec team(Role.Doctor.t()) :: Role.team()
  def team(_), do: :citizen

  @impl true
  @spec priority(Role.Doctor.t()) :: non_neg_integer()
  def priority(_), do: 2

  @impl true
  @spec display_name(Role.Doctor.t()) :: String.t()
  def display_name(_), do: "의사"

  @impl true
  @spec begin_phase(Role.Doctor.t(), State.phase(), State.id(), State.t()) :: State.t()
  def begin_phase(_, :night, player_id, state) do
    targets =
      state.players
      |> Enum.filter(fn {_id, player} -> player.alive end)
      |> Enum.sort_by(fn {_id, %{name: name}} -> String.length(name) end)
      |> Enum.with_index()
      |> Enum.map(fn {{_id, player}, index} -> {index, player} end)
      |> Map.new()

    put_in(state, [:players, player_id, :role, :targets], targets)
  end
  def begin_phase(_, _, _, state), do: state

  @impl true
  @spec available_targets(Role.Doctor.t(), State.phase()) :: Role.Doctor.targets()
  def available_targets(%{targets: targets}, :night), do: targets
  def available_targets(_, _), do: %{}

  @impl true
  @spec register_ability(Role.Doctor.t(), State.phase(), State.id(), State.t()) :: {String.t(), State.t()}
  def register_ability(_, :night, _target_id, state) do
    # new_pending_actions =
    #   state
    #   |> Map.put(role.name, %{
    #     priority: 2,
    #     action: :heal,
    #     target: target_id
    #   })

    {"", state}
  end
  def register_ability(_, _, _, _, state), do: {"사용할 수 있는 능력이 없습니다.", state}

  @impl true
  @spec resolve_ability(Role.Doctor.t(), State.phase(), State.t()) :: State.t()
  def resolve_ability(_, _, state), do: state
end
