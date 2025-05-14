defprotocol Mafia.Game.Role do
  alias Mafia.Game.State
  alias Mafia.Game.Player

  @type team() :: :citizen | :mafia | :neutral

  @spec atom(t()) :: atom()
  def atom(role)

  @spec team(t()) :: team()
  def team(role)

  @doc """
  0: no ability
  1: attack
  2: defense
  """
  @spec priority(t()) :: non_neg_integer()
  def priority(role)

  @spec display_name(t()) :: String.t()
  def display_name(role)

  @spec begin_phase(t(), State.phase(), State.id(), State.t()) :: State.t()
  def begin_phase(role, phase, player_id, state)

  @spec available_targets(t(), State.phase()) :: %{pos_integer() => Player.t()}
  def available_targets(role, phase)

  @spec register_ability(t(), State.phase(), State.id(), State.t()) :: {String.t(), State.t()}
  def register_ability(role, phase, target_id, state)

  @spec resolve_ability(t(), State.phase(), State.t()) :: State.t()
  def resolve_ability(role, phase, state)
end
