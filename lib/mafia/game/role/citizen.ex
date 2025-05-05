defmodule Mafia.Game.Role.Citizen do
  defstruct [:name, :team, :targets]

  def new do
    %__MODULE__{
      name: :citizen,
      team: :citizen,
      targets: []
    }
  end
end

defimpl Mafia.Game.Role, for: Mafia.Game.Role.Citizen do
  def atom(_), do: :citizen
  def display_name(_), do: "시민"
  def target_list(_, _), do: []
  def perform_action(_, game_state, _), do: game_state
end
