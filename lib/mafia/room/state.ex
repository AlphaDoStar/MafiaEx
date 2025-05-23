defmodule Mafia.Room.State do
  @moduledoc """
  Mafia.Room.Server의 상태 구조체
  """
  alias Mafia.Game.Role

  @type id :: String.t()
  @type settings :: %{
    mafia_count: pos_integer() | nil,
    active_roles: %{module() => boolean()}
  }
  @type member :: %{
    name: String.t(),
    meeting: atom()
  }
  @type t :: %__MODULE__{
    id: id(),
    name: String.t(),
    host: id(),
    game_started: boolean(),
    settings: settings(),
    members: %{id() => member()},
    meetings: %{atom() => [id()]}
  }

  @enforce_keys [:id, :name, :host, :members]
  defstruct [
    :id,
    :name,
    :host,
    :members,
    game_started: false,
    settings: %{
      mafia_count: nil,
      active_roles: Role.Manager.default_active_roles()
    },
    meetings: %{}
  ]

  @behaviour Access

  @impl true
  def fetch(struct, key), do:  Map.fetch(struct, key)

  @impl true
  def get_and_update(struct, key, fun), do: Map.get_and_update(struct, key, fun)

  @impl true
  def pop(struct, key), do: Map.pop(struct, key)

  @spec new(id(), {id(), String.t()}) :: t()
  def new(id, {host_id, host_name}) do
    %__MODULE__{
      id: id,
      name: "#{host_name}의 방",
      host: host_id,
      members: %{
        host_id => %{
          name: host_name,
          meeting: nil
        }
      }
    }
  end
end
