defmodule Mafia.Game.Role.Doctor do
  alias Mafia.Game.Player

  @type id :: String.t()
  @type targets :: %{pos_integer() => Player.t()}
  @type t :: %__MODULE__{
    targets: targets()
  }

  defstruct [:targets]

  @behaviour Access

  @impl true
  def fetch(struct, key), do:  Map.fetch(struct, key)

  @impl true
  def get_and_update(struct, key, fun), do: Map.get_and_update(struct, key, fun)

  @impl true
  def pop(struct, key), do: Map.pop(struct, key)

  @spec new() :: t()
  def new do
    %__MODULE__{
      targets: %{}
    }
  end
end

defimpl Mafia.Game.Role, for: Mafia.Game.Role.Doctor do
  alias Mafia.Game.{Player, Role, State}

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
      |> Enum.with_index(1)
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
  def register_ability(role, :night, target_id, %State{} = state) do
    new_state = put_in(state, [:phase_states, :night, :targets, role.__struct__], target_id)
    target = new_state.players[target_id]
    message =
      """
      #{target.name} 님을
      치료 대상으로 지정하였습니다.
      """
      |> String.trim_trailing()

    {message, new_state}
  end
  def register_ability(_, _, _, state), do: {"사용할 수 있는 능력이 없습니다.", state}

  @impl true
  @spec resolve_ability(Role.Doctor.t(), State.phase(), State.id(), State.t()) :: State.t()
  def resolve_ability(_, :night, target_id, %State{} = state) do
    case state.players[target_id] do
      %Player{alive: true} ->
        state

      %Player{alive: false, name: name} ->
        message =
          """
          #{name} 님이
          의사의 치료로 살아났습니다.
          """
          |> String.trim_trailing()

        state
        |> put_in([:players, target_id, :alive], true)
        |> put_in([:phase_states, :night, :result, :message], message)
    end
  end
  def resolve_ability(_, _, _, state), do: state

  @impl true
  @spec kill_player(Role.Doctor.t(), State.phase(), State.id(), State.t()) :: {String.t(), State.t()}
  def kill_player(_, _, player_id, state) do
    new_state = put_in(state, [:players, player_id, :alive], false)
    player = new_state.players[player_id]
    message = "#{player.name} 님이 사망했습니다."
    {message, new_state}
  end
end
