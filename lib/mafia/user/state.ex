defmodule Mafia.User.State do
  use GenServer

  @impl true
  @spec init(:ok) :: {:ok, map()}
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:join_room, user_id, room_id}, _from, state) do
    new_state = Map.put(state, user_id, room_id)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:leave_room, user_id}, _from, state) do
    new_state = Map.delete(state, user_id)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:get_room, user_id}, _from, state) do
    room_id = Map.get(state, user_id, :not_in_room)
    {:reply, room_id, state}
  end
end
