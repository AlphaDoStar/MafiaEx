defmodule Mafia.Game.Role.Lover do
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

defimpl Mafia.Game.Role, for: Mafia.Game.Role.Lover do
  alias Mafia.Game.{Role, State}

  @impl true
  @spec atom(Role.Lover.t()) :: atom()
  def atom(_), do: :lover

  @impl true
  @spec team(Role.Lover.t()) :: Role.team()
  def team(_), do: :citizen

  @impl true
  @spec priority(Role.Lover.t()) :: non_neg_integer()
  def priority(_), do: 0

  @impl true
  @spec display_name(Role.Lover.t()) :: String.t()
  def display_name(_), do: "연인"

  @impl true
  @spec begin_phase(Role.Lover.t(), State.phase(), State.id(), State.t()) :: State.t()
  def begin_phase(_, _, _, state), do: state

  @impl true
  @spec available_targets(Role.Lover.t(), State.phase()) :: Role.Lover.targets()
  def available_targets(_, _), do: %{}

  @impl true
  @spec register_ability(Role.Lover.t(), State.phase(), State.id(), State.t()) :: {String.t(), State.t()}
  def register_ability(_, _, _, state), do: {"사용할 수 있는 능력이 없습니다.", state}

  @impl true
  @spec resolve_ability(Role.Lover.t(), State.phase(), State.id(), State.t()) :: State.t()
  def resolve_ability(_, _, _, state), do: state

  @impl true
  @spec kill_player(Role.Lover.t(), State.phase(), State.id(), State.t()) :: {String.t(), State.t()}
  def kill_player(_, _, player_id, state) do
    case Enum.find(state.players, &lover_and_alive?/1) do
      nil ->
        new_state = put_in(state, [:players, player_id, :alive], false)
        player = get_in(state, [:players, player_id])
        message = "#{player.name} 님이 사망했습니다."
        {message, new_state}

      {id, partner} ->
        new_state = put_in(state, [:players, id, :alive], false)
        player = get_in(state, [:players, player_id])
        message =
          """
          #{partner.name} 님이
          연인 #{player.name} 님을 대신하여
          희생했습니다.
          """
          |> String.trim_trailing()

        {message, new_state}
    end
  end

  defp lover_and_alive?({_id, player}) do
    Role.atom(player.role) === :lover and player.alive
  end
end
