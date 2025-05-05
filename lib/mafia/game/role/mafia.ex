defmodule Mafia.Game.Role.Mafia do
  defstruct [:name, :team, :targets]

  def new do
    %__MODULE__{
      name: :mafia,
      team: :mafia,
      targets: []
    }
  end
end

defimpl Mafia.Game.Role, for: Mafia.Game.Role.Mafia do
  def atom(_), do: :mafia
  def display_name(_), do: "마피아"

  def target_list(_, %{players: players}) do
    players
    |> Map.to_list()
    |> Enum.filter(fn {_id, player} ->
      player.role.name !== :mafia and player.alive
    end)
  end

  def perform_action(role, game_state, target_id) do
    new_pending_actions =
      game_state.pending_actions
      |> Map.put(role.name, %{
        priority: 1,
        action: :kill,
        target: target_id
      })

    %{game_state | pending_actions: new_pending_actions}
  end
end
