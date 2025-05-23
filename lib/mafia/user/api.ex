defmodule Mafia.User.API do
  alias Mafia.User.Server

  def child_spec(args) do
    %{
      id: Mafia.User,
      start: {Mafia.User.API, :start_link, [args]},
      restart: :permanent,
      type: :worker
    }
  end

  def start_link(_) do
    GenServer.start_link(Server, :ok, name: Server)
  end

  def join_room(user_id, room_id) do
    GenServer.call(Server, {:join_room, user_id, room_id})
  end

  def leave_room(user_id) do
    GenServer.call(Server, {:leave_room, user_id})
  end

  def room_id(user_id) do
    GenServer.call(Server, {:room_id, user_id})
  end
end
