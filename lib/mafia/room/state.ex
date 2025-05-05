defmodule Mafia.Room.State do
  @moduledoc """
  Mafia.Room.Server의 상태 구조체
  """

  @type id :: String.t()
  @type settings :: %{
    mafia_count: pos_integer() | nil,
    active_roles: %{module() => boolean()}
  }
  @type t :: %__MODULE__{
    id: id(),
    name: String.t(),
    host: id(),
    game_started: boolean(),
    settings: settings(),
    members: %{
      id() => %{
        name: String.t(),
        meeting: id() | nil
      }
    },
    meetings: %{
      id() => %{
        name: String.t(),
        members: %{id() => boolean()}  # mute
      }
    }
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
      active_roles: Mafia.Game.Role.Manager.default_active_roles()
    },
    meetings: %{}
  ]

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
