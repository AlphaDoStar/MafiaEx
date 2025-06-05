defmodule Mafia.Room.API do
  alias Mafia.Room.State

  def start_link(args) do
    GenServer.start_link(Mafia.Room.Server, Map.new(args), name: via_tuple(args[:id]))
  end

  @spec host?(State.id(), State.id()) :: boolean()
  def host?(room_id, user_id) do
    GenServer.call(via_tuple(room_id), {:host?, user_id})
  end

  @spec set_name(State.id(), String.t()) :: :ok
  def set_name(room_id, name) do
    GenServer.call(via_tuple(room_id), {:set_name, name})
  end

  @spec name(State.id()) :: String.t()
  def name(room_id) do
    GenServer.call(via_tuple(room_id), :name)
  end

  @spec add_member(State.id(), State.id(), String.t()) :: :ok
  def add_member(room_id, user_id, user_name) do
    GenServer.call(via_tuple(room_id), {:add_member, user_id, user_name})
  end

  @spec transfer_host(State.id(), State.id()) :: :ok
  def transfer_host(room_id, user_id) do
    GenServer.call(via_tuple(room_id), {:transfer_host, user_id})
  end

  @spec member_count(State.id()) :: pos_integer()
  def member_count(room_id) do
    GenServer.call(via_tuple(room_id), :member_count)
  end

  @spec remove_member(State.id(), State.id()) :: :ok
  def remove_member(room_id, user_id) do
    GenServer.call(via_tuple(room_id), {:remove_member, user_id})
  end

  @spec broadcast_message(State.id(), String.t()) :: :ok
  @spec broadcast_message(State.id(), String.t(), boolean()) :: :ok
  def broadcast_message(room_id, message, prefix \\ true) do
    GenServer.call(via_tuple(room_id), {:broadcast_message, message, prefix})
  end

  @spec broadcast_member_message(State.id(), State.id(), String.t()) :: :ok
  def broadcast_member_message(room_id, user_id, message) do
    GenServer.call(via_tuple(room_id), {:broadcast_member_message, user_id, message})
  end

  @spec toggle_active_roles(State.id(), [pos_integer()]) :: :ok
  def toggle_active_roles(room_id, indices) do
    GenServer.call(via_tuple(room_id), {:toggle_active_roles, indices})
  end

  @spec state(State.id()) :: State.t()
  def state(room_id) do
    GenServer.call(via_tuple(room_id), :state)
  end

  @type create_meeting_opts :: [muted: boolean(), speakers: [State.id()]]
  @spec create_meeting(State.id(), atom(), [State.id()], create_meeting_opts()) :: State.id()
  def create_meeting(room_id, meeting_name, member_ids, opts \\ []) do
    GenServer.call(via_tuple(room_id), {:create_meeting, meeting_name, member_ids, opts})
  end

  @spec end_meetings(State.id()) :: :ok
  def end_meetings(room_id) do
    GenServer.call(via_tuple(room_id), :end_meetings)
  end

  @spec end_room(State.id()) :: :ok
  def end_room(room_id) do
    GenServer.call(via_tuple(room_id), :end_room)
  end

  defp via_tuple(room_id) do
    {:via, Registry, {Mafia.Room.Registry, room_id}}
  end
end
