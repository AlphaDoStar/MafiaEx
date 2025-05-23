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

  @behaviour Access

  @impl true
  def fetch(struct, key), do:  Map.fetch(struct, key)

  @impl true
  def get_and_update(struct, key, fun), do: Map.get_and_update(struct, key, fun)

  @impl true
  def pop(struct, key), do: Map.pop(struct, key)

  @spec new(id(), String.t()) :: t()
  def new(id, name) do
    %__MODULE__{
      id: id,
      name: name,
      role: Role.Unknown.new()
    }
  end
end
