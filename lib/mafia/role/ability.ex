defmodule Mafia.Role.Ability do
  @moduledoc """
  마피아 직업 behaviour 정의 모듈
  """
  alias Mafia.Types

  @callback role_name :: String.t()

  @callback team :: Types.team()

  @callback phase :: Types.phase()

  @callback priority :: non_neg_integer()

  @callback can_use?(game_state :: Types.game_state(), player :: Types.player()) :: boolean()

  @callback execute(game_state :: Types.game_state(), player :: Types.player(), target :: Types.player()) ::
    {:ok, Types.game_state()} | {:error, String.t()}
end
