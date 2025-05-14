defmodule Mafia.Game.Player do
  @moduledoc """
  Mafia.Game.Server의 플레이어 구조체
  """
  alias Mafia.Game.Role

  @type id :: String.t()
  @type t :: %__MODULE__{
    id: id(),
    name: String.t(),
    role: Role.t(),
    alive: boolean()
  }

  @enforce_keys [:id, :name, :role]
  defstruct [
    :id,
    :name,
    :role,
    alive: true
  ]

  @spec new(id(), String.t()) :: t()
  def new(id, name) do
    %__MODULE__{
      id: id,
      name: name,
      role: Role.Unknown.new()
    }
  end
end
