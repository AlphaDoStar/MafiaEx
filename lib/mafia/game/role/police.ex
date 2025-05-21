defmodule Mafia.Game.Role.Police do
  @type id :: String.t()
  @type targets :: %{pos_integer() => id}
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

defimpl Mafia.Game.Role, for: Mafia.Game.Role.Police do
  alias Mafia.Game.{Role, State}

  @impl true
  @spec atom(Role.Police.t()) :: atom()
  def atom(_), do: :police

  @impl true
  @spec team(Role.Police.t()) :: Role.team()
  def team(_), do: :citizen

  @impl true
  @spec priority(Role.Police.t()) :: non_neg_integer()
  def priority(_), do: 0

  @impl true
  @spec display_name(Role.Police.t()) :: String.t()
  def display_name(_), do: "경찰"

  @impl true
  @spec begin_phase(Role.Police.t(), State.phase(), State.id(), State.t()) :: State.t()
  def begin_phase(_, :night, player_id, state) do
    targets =
      state.players
      |> Enum.filter(&not_police_and_alive?/1)
      |> Enum.sort_by(fn {_id, %{name: name}} -> String.length(name) end)
      |> Enum.with_index()
      |> Enum.map(fn {{_id, player}, index} -> {index, player} end)
      |> Map.new()

    put_in(state, [:players, player_id, :role, :targets], targets)
  end
  def begin_phase(_, _, _, state), do: state

  @impl true
  @spec available_targets(Role.Police.t(), State.phase()) :: Role.Police.targets()
  def available_targets(%{targets: targets}, :night), do: targets
  def available_targets(_, _), do: %{}

  @impl true
  @spec register_ability(Role.Police.t(), State.phase(), State.id(), State.t()) :: {String.t(), State.t()}
  def register_ability(role, :night, target_id, state) do
    keys = [:phase_states, :night, :targets, role.__struct__]
    case get_in(state, keys) do
      nil ->
        new_state = put_in(state, keys, target_id)
        target = get_in(state, [:players, target_id])
        message =
          if Role.team(target.role) === :mafia do
            "#{target.name} 님은 마피아입니다."
          else
            "#{target.name} 님은 마피아가 아닙니다."
          end

        {message, new_state}

      _ -> {"이미 능력을 사용했습니다.", state}
    end
  end
  def register_ability(_, _, _, state), do: {"사용할 수 있는 능력이 없습니다.", state}

  @impl true
  @spec resolve_ability(Role.Police.t(), State.phase(), State.id(), State.t()) :: State.t()
  def resolve_ability(_, _, _, state), do: state

  @impl true
  @spec kill_player(Role.Police.t(), State.phase(), State.id(), State.t()) :: {String.t(), State.t()}
  def kill_player(_, _, player_id, state) do
    new_state = put_in(state, [:players, player_id, :alive], false)
    player = get_in(state, [:players, player_id])
    message = "#{player.name} 님이 사망했습니다."
    {message, new_state}
  end

  defp not_police_and_alive?({_id, player}) do
    Role.atom(player.role) === :police and player.alive
  end
end
