defmodule Mafia.User.API do
  alias Mafia.User.State

  def child_spec(args) do
    %{
      id: Mafia.User,
      start: {Mafia.User.API, :start_link, [args]},
      restart: :permanent,
      type: :worker
    }
  end

  def start_link(_) do
    GenServer.start_link(State, :ok, name: State)
  end

  def join_room(user_id, room_id) do
    GenServer.call(State, {:join_room, user_id, room_id})
  end

  def leave_room(user_id) do
    GenServer.call(State, {:leave_room, user_id})
  end

  def get_room(user_id) do
    GenServer.call(State, {:get_room, user_id})
  end
end
