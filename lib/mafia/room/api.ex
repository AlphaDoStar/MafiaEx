defmodule Mafia.Room.API do
  alias Mafia.Types

  @spec start_link([{:id, Types.id()}, {:host, {Types.id(), String.t()}}]) ::
    GenServer.on_start()
  def start_link(args) do
    GenServer.start_link(Mafia.Room.State, args, name: via_tuple(args[:id]))
  end

  @spec is_host?(Types.id(), Types.id()) :: boolean()
  def is_host?(room_id, user_id) do
    GenServer.call(via_tuple(room_id), {:is_host?, user_id})
  end

  @spec is_game_started?(Types.id()) :: boolean()
  def is_game_started?(room_id) do
    GenServer.call(via_tuple(room_id), :is_game_started?)
  end

  @spec set_name(Types.id(), String.t()) :: :ok
  def set_name(room_id, name) do
    GenServer.call(via_tuple(room_id), {:set_name, name})
  end

  @spec get_name(Types.id()) :: String.t()
  def get_name(room_id) do
    GenServer.call(via_tuple(room_id), :get_name)
  end

  @spec add_member(Types.id(), Types.id(), String.t()) :: :ok
  def add_member(room_id, user_id, user_name) do
    GenServer.call(via_tuple(room_id), {:add_member, user_id, user_name})
  end

  @spec transfer_host(Types.id(), Types.id()) :: :ok
  def transfer_host(room_id, user_id) do
    GenServer.call(via_tuple(room_id), {:transfer_host, user_id})
  end

  @spec get_member_count(Types.id()) :: non_neg_integer()
  def get_member_count(room_id) do
    GenServer.call(via_tuple(room_id), :get_member_count)
  end

  @spec remove_member(Types.id(), Types.id()) :: :ok
  def remove_member(room_id, user_id) do
    GenServer.call(via_tuple(room_id), {:remove_member, user_id})
  end

  @spec broadcast_message(Types.id(), String.t()) :: :ok
  def broadcast_message(room_id, message) do
    GenServer.call(via_tuple(room_id), {:broadcast_message, message})
  end

  @spec broadcast_member_message(Types.id(), Types.id(), String.t()) :: :ok
  def broadcast_member_message(room_id, user_id, message) do
    GenServer.call(via_tuple(room_id), {:broadcast_member_message, user_id, message})
  end

  @spec create_meeting(Types.id(), String.t(), %{Types.id() => boolean()}) :: Types.id()
  def create_meeting(room_id, meeting_name, members) do
    GenServer.call(via_tuple(room_id), {:create_meeting, meeting_name, members})
  end

  @spec end_meeting(Types.id()) :: :ok
  def end_meeting(room_id) do
    GenServer.call(via_tuple(room_id), :end_meeting)
  end

  @spec end_room(Types.id()) :: :ok
  def end_room(room_id) do
    GenServer.call(via_tuple(room_id), :end_room)
  end

  def via_tuple(room_id) do
    {:via, Registry, {Mafia.Room.Registry, room_id}}
  end
end
