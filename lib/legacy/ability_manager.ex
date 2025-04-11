defmodule Mafia.AbilityManager do
  @moduledoc """
  마피아 직업 관리 모듈
  """
  alias Mafia.Types
  alias Mafia.Role.Mapper
  require Logger

  @spec process_night_abilities(Types.game_state()) :: Types.game_state()
  def process_night_abilities(game_state) do
    game_state.players
    |> Map.values()
    |> Enum.filter(fn player -> player.alive? end)
    |> Enum.map(fn player -> {player, Mapper.get_modules(player.role)} end)
    |> Enum.filter(fn {_player, role} -> role.phase() == :night end)
    |> Enum.sort_by(fn {_player, role} -> role.priority() end)
    |> Enum.reduce(game_state, &apply_ability/2)
  end

  defp apply_ability({player, role_module}, game_state) do
    with target_id when not is_nil(target_id) <- player.target_id,
      target <- game_state.players[target_id],
      true <- role_module.can_use?(game_state, player),
      {:ok, new_state} <- role_module.execute(game_state, player, target) do
      new_state
    else
      nil -> game_state
      false -> game_state
      {:error, reason} ->
        Logger.error(reason)
        game_state
    end
  end
end
