defmodule Mafia.Game.Supervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def create_game(room_id) do
    spec = %{
      id: :undefined,
      start: {Mafia.Game.API, :start_link, [Mafia.Room.API.state(room_id)]},
      restart: :transient
    }

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, _pid} -> {:ok, :success}
      {:error, reason} -> {:error, reason}
    end
  end

  def create_timer(game_id) do
    spec = %{
      id: :undefined,
      start: {Mafia.Game.Timer, :start_link, [game_id]},
      restart: :transient
    }

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, _pid} -> {:ok, :success}
      {:error, reason} -> {:error, reason}
    end
  end

  def game_exists?(game_id) do
    case Registry.lookup(Mafia.Game.Registry, game_id) do
      [] -> false
      [{pid, _}] -> Process.alive?(pid)
    end
  end
end
