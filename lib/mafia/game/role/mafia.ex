defmodule Mafia.Game.Role.Mafia do
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

defimpl Mafia.Game.Role, for: Mafia.Game.Role.Mafia do
  alias Mafia.Game.{Role, State}

  @impl true
  @spec atom(Role.Mafia.t()) :: atom()
  def atom(_), do: :mafia

  @impl true
  @spec team(Role.Mafia.t()) :: Role.team()
  def team(_), do: :mafia

  @impl true
  @spec priority(Role.Mafia.t()) :: non_neg_integer()
  def priority(_), do: 1

  @impl true
  @spec display_name(Role.Mafia.t()) :: String.t()
  def display_name(_), do: "마피아"

  @impl true
  @spec begin_phase(Role.Mafia.t(), State.phase(), State.id(), State.t()) :: State.t()
  def begin_phase(_, :night, player_id, state) do
    targets =
      state.players
      |> Enum.filter(&not_mafia_and_alive?/1)
      |> Enum.sort_by(fn {_id, %{name: name}} -> String.length(name) end)
      |> Enum.with_index()
      |> Enum.map(fn {{_id, player}, index} -> {index, player} end)
      |> Map.new()

    put_in(state, [:players, player_id, :role, :targets], targets)
  end
  def begin_phase(_, _, _, state), do: state

  @impl true
  @spec available_targets(Role.Mafia.t(), State.phase()) :: Role.Mafia.targets()
  def available_targets(%{targets: targets}, :night), do: targets
  def available_targets(_, _), do: %{}

  @impl true
  @spec register_ability(Role.Mafia.t(), State.phase(), State.id(), State.t()) :: {String.t(), State.t()}
  def register_ability(role, :night, target_id, state) do
    new_state = put_in(state, [:phase_states, :night, :targets, role.__struct__], target_id)
    target = get_in(state, [:players, target_id])
    message =
      """
      #{target.name} 님을
      암살 대상으로 지정하였습니다.
      """
      |> String.trim_trailing()

    {message, new_state}
  end
  def register_ability(_, _, _, state), do: {"사용할 수 있는 능력이 없습니다.", state}

  @impl true
  @spec resolve_ability(Role.Mafia.t(), State.phase(), State.id(), State.t()) :: State.t()
  def resolve_ability(_, :night, target_id, state) do
    {message, new_state} =
      state
      |> get_in([:players, target_id, :role])
      |> Role.kill_player(:night, target_id, state)

    put_in(new_state, [:phase_states, :night, :result, :message], message)
  end
  def resolve_ability(_, _, _, state), do: state

  @impl true
  @spec kill_player(Role.Mafia.t(), State.phase(), State.id(), State.t()) :: {String.t(), State.t()}
  def kill_player(_, _, player_id, state) do
    new_state = put_in(state, [:players, player_id, :alive], false)
    player = get_in(state, [:players, player_id])
    message = "#{player.name} 님이 사망했습니다."
    {message, new_state}
  end

  defp not_mafia_and_alive?({_id, player}) do
    Role.atom(player.role) !== :mafia and player.alive
  end
end
