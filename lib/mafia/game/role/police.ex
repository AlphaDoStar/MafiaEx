defmodule Mafia.Game.Role.Police do
  defstruct [:name, :team, :targets]

  def new do
    %__MODULE__{
      name: :police,
      team: :citizen,
      targets: []
    }
  end
end

defimpl Mafia.Game.Role, for: Mafia.Game.Role.Police do
  def atom(_), do: :police
  def display_name(_), do: "경찰"

  def target_list(_, %{players: players}) do
    players
    |> Map.to_list()
    |> Enum.filter(fn {_id, player} ->
      player.role.name !== :police and player.alive
    end)
  end

  def perform_action(role, game_state, target_id) do
    new_pending_actionss =
      game_state.pending_actions
      |> Map.put(role.name, %{
        priority: 3,
        action: :investigate,
        target: target_id
      })

    %{game_state | pending_actions: new_pending_actionss}
  end
end
