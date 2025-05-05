defmodule Mafia.Game.Player do
  @moduledoc """
  Mafia.Game.Server의 플레이어 구조체
  """

  @type id :: String.t()
  @type t :: %__MODULE__{
    id: id(),
    name: String.t(),
    role: Mafia.Game.Role.t(),
    alive: boolean()
  }

  @enforce_keys [:id, :name, :role]
  defstruct [
    :id,
    :name,
    :role,
    alive: true
  ]

  def new(id, name) do
    %__MODULE__{
      id: id,
      name: name,
      role: Mafia.Game.Role.Unknown.new()
    }
  end
end
