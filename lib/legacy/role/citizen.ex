defmodule Mafia.Role.Citizen do
  use Mafia.Role.Registry
  alias Mafia.Types

  @role_name "시민"
  @team :citizen
  @phase :day
  @priority 0

  @impl true
  @spec can_use?(Types.game_state(), Types.player()) :: boolean()
  def can_use?(_game_state, _player), do: false

  @impl true
  @spec execute(Types.game_state(), Types.player(), Types.player()) :: {:ok, Types.game_state()} | {:error, String.t()}
  def execute(game_state, _player, _target), do: {:ok, game_state}
end
