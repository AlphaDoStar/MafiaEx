defmodule Mafia.Room.Supervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def create_room(user_id, user_name) do
    room_id = UUID.uuid4()
    spec = %{
      id: :undefined,
      start: {Mafia.Room.API, :start_link, [[id: room_id, host: {user_id, user_name}]]},
      restart: :transient
    }

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, _pid} -> {:ok, room_id}
      {:error, {:already_started, _pid}} -> {:error, :already_exists}
      {:error, reason} -> {:error, reason}
    end
  end

  def room_exists?(room_id) do
    case Registry.lookup(Mafia.Room.Registry, room_id) do
      [] -> false
      [{pid, _}] -> Process.alive?(pid)
    end
  end

  def get_all_room_ids do
    Registry.select(Mafia.Room.Registry, [{{:"$1", :"$2", :"$3"}, [], [:"$1"]}])
  end

  def get_all_room_names do
    get_all_room_ids()
    |> Enum.map(&Mafia.Room.API.get_name/1)
  end
end
