defmodule Mafia.Game.Role.Doctor do
  defstruct [:name, :team, :targets]

  def new do
    %__MODULE__{
      name: :doctor,
      team: :citizen,
      targets: []
    }
  end
end

defimpl Mafia.Game.Role, for: Mafia.Game.Role.Doctor do
  def atom(_), do: :doctor
  def display_name(_), do: "의사"

  def target_list(_, %{players: players}) do
    players
    |> Map.to_list()
    |> Enum.filter(fn {_id, player} -> player.alive end)
  end

  def perform_action(role, game_state, target_id) do
    new_pending_actions =
      game_state
      |> Map.put(role.name, %{
        priority: 2,
        action: :heal,
        target: target_id
      })

    %{game_state | pending_actions: new_pending_actions}
  end
end
