defmodule Mafia.User.Agent do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def join_room(user_id, room_id) do
    Agent.update(__MODULE__, &Map.put(&1, user_id, room_id))
  end

  def leave_room(user_id) do
    Agent.update(__MODULE__, &Map.delete(&1, user_id))
  end

  def room_id(user_id) do
    Agent.get(__MODULE__, &Map.get(&1, user_id))
  end
end
