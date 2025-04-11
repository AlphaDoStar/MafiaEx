defmodule Mafia.Role.Mafia do
  use Mafia.Role.Registry
  alias Mafia.Types

  @role_name "마피아"
  @team :mafia
  @phase :night
  @priority 1

  @impl true
  @spec can_use?(Types.game_state(), Types.player()) :: boolean()
  def can_use?(game_state, player) do
    game_state.phase == :night && player.alive?
  end

  @impl true
  @spec execute(Types.game_state(), Types.player(), Types.player()) :: {:ok, Types.game_state()} | {:error, String.t()}
  def execute(game_state, _player, target) do
    try do
      new_state =
        game_state
        |> put_in([:players, target.id, :alive?], false)
        |> Map.put(:night_event, %{action: :death, target: target.name})

      {:ok, new_state}
    rescue
      error -> {:error, inspect(error, pretty: true)}
    end
  end
end
