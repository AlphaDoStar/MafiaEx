defmodule Mafia.Room.State do
  use GenServer
  alias Mafia.Types

  @impl true
  @spec init([{:id, Types.id()}, {:host, {Types.id(), String.t()}}]) ::
    {:ok, Types.room_state()}
  def init(id: _room_id, host: {host_id, host_name}) do
    {:ok, %{
      # id: room_id,
      name: nil,
      host: host_id,
      game_started: false,
      members: %{host_id => %{name: host_name, meeting: nil}},
      meetings: %{}
    }}
  end

  @impl true
  def handle_call({:is_host?, id}, _from, state) do
    comparison = state.host === id
    {:reply, comparison, state}
  end

  @impl true
  def handle_call(:is_game_started?, _from, state) do
    {:reply, state.game_started, state}
  end

  @impl true
  def handle_call({:set_name, name}, _from, state) do
    new_state = Map.put(state, :name, name)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:get_name, _from, state) do
    {:reply, state.name, state}
  end

  @impl true
  def handle_call({:add_member, id, name}, _from, state) do
    new_state = put_in(state, [:members, id], %{name: name, meeting: nil})
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:transfer_host, id}, _from, state) do
    new_state = Map.put(state, :host, id)
    host_name = new_state.members[id].name
    {:reply, host_name, new_state}
  end

  @impl true
  def handle_call(:get_member_count, _from, state) do
    {:reply, map_size(state.members), state}
  end

  @impl true
  def handle_call({:remove_member, id}, _from, state) do
    member = state.members[id]
    new_state = state
      |> update_in([:members], &Map.delete(&1, id))
      |> update_in([:meetings], &Map.delete(&1, member.meeting))

    {:reply, member.name, new_state}
  end

  @impl true
  def handle_call({:broadcast_message, message}, _from, state) do
    recipients = Map.keys(state.members)
    text = "☾ Mafia ⟩  #{message}"
    Mafia.Messenger.send_text_to_many(recipients, text)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:broadcast_member_message, user_id, message}, _from, state) do
    user = state.members[user_id]
    recipients =
      if is_nil(user.meeting) do
        state.members
        |> Map.keys()
        |> Enum.filter(fn member_id -> member_id !== user_id end)
      else
        meeting = Map.get(state.meetings, user.meeting)
        meeting.members
        |> Map.keys()
        |> Enum.filter(fn member_id -> member_id !== user_id end)
      end

    text = "💬 #{user.name} ⟩  #{message}"
    Mafia.Messenger.send_text_to_many(recipients, text)
    {:reply, :ok, state}
  end

  @impl true
  @spec handle_call({:create_meeting, String.t(), %{Types.id() => boolean()}}, GenServer.from(), Types.room_state()) ::
    {:reply, Types.id(), Types.room_state()}
  def handle_call({:create_meeting, name, members}, _from, state) do
    uuid = UUID.uuid4()
    new_state = Map.put(state, uuid, %{name: name, members: members})
    {:reply, uuid, new_state}  # 수정 필요
  end

  @impl true
  def handle_call(:end_meeting, _from, state) do
    new_state = Map.put(state, :meetings, %{})
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:end_room, _from, state) do
    {:stop, :normal, :ok, state}
  end
end

%{
  id: "room id",
  name: "room name",
  host: "user id",
  game_started: true,
  members: %{"user id" => %{name: "user name", meeting: "meeting id"}},
  meetings: %{"meeting id" => %{name: "meeting name", members: %{"user id" => false}}}
}
