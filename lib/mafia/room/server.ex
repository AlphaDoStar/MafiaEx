defmodule Mafia.Room.Server do
  use GenServer
  alias Mafia.Room.State

  @impl true
  def init(%{id: id, host: {host_id, host_name}}) do
    {:ok, Mafia.Room.State.new(id, {host_id, host_name})}
  end

  @impl true
  def handle_call({:host?, id}, _from, %State{} = state) do
    comparison = state.host == id
    {:reply, comparison, state}
  end

  @impl true
  def handle_call({:set_name, name}, _from, %State{} = state) do
    new_state = Map.put(state, :name, name)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:name, _from, %State{} = state) do
    {:reply, state.name, state}
  end

  @impl true
  def handle_call({:add_member, id, name}, _from, %State{} = state) do
    new_state = put_in(state, [:members, id], %{name: name, meeting: nil})
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:member_count, _from, %State{} = state) do
    {:reply, map_size(state.members), state}
  end

  @impl true
  def handle_call({:transfer_host, id}, _from, %State{} = state) do
    new_state = Map.put(state, :host, id)
    host_name = new_state.members[id][:name]
    {:reply, host_name, new_state}
  end

  @impl true
  def handle_call({:remove_member, id}, _from, %State{} = state) do
    member = state.members[id]
    new_state =
      state
      |> update_in([:members], &Map.delete(&1, id))
      |> update_in([:meetings, member.meeting], &List.delete(&1, id))

    {:reply, member.name, new_state}
  end

  @impl true
  def handle_call({:broadcast_message, message, prefix}, _from, %State{} = state) do
    recipients = Map.keys(state.members)
    text = if prefix, do: "◐ Mafia ⟩  #{message}", else: message
    Mafia.Messenger.send_text_to_many(recipients, text)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:broadcast_member_message, user_id, message}, _from, %State{} = state) do
    user = state.members[user_id]

    lobby_members = lobby_members(state, user_id)
    meeting_members = meeting_members(state, user_id, user.meeting)
    recipients = lobby_members ++ meeting_members

    text = "💬 #{user.name} ⟩  #{message}"
    Mafia.Messenger.send_text_to_many(recipients, text)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:toggle_active_roles, indices}, _from, %State{} = state) do
    new_active_roles =
      state.settings.active_roles
      |> Enum.with_index(1)
      |> Enum.map(fn {{module, active}, index} ->
        {module, (if index in indices, do: !active, else: active)}
      end)
      |> Map.new()

    new_state = put_in(state, [:settings, :active_roles], new_active_roles)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:game_started?, _from, %State{} = state) do
    {:reply, state.game_started, state}
  end

  @impl true
  def handle_call(:state, _from, %State{} = state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:create_meeting, name, ids}, _from, %State{} = state) do
    id_set = MapSet.new(ids)
    new_state =
      state
      |> put_in([:meetings, name], ids)
      |> Map.update!(:members, fn members ->
        Enum.map(members, fn {id, member} ->
          new_member =
            if MapSet.member?(id_set, id) do
              %{member | meeting: name}
            else
              member
            end

          {id, new_member}
        end)
        |> Map.new()
      end)

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:end_meetings, _from, %State{} = state) do
    new_state =
      state
      |> Map.put(:meetings, %{})
      |> Map.update!(:members, fn members ->
        members
        |> Enum.map(fn {id, member} -> {id, %{member | meeting: nil}} end)
        |> Map.new()
      end)

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:end_room, _from, %State{} = state) do
    {:stop, :normal, :ok, state}
  end

  defp lobby_members(state, user_id) do
    state.members
    |> Enum.filter(fn {id, member} ->
      id != user_id and is_nil(member.meeting)
    end)
    |> Enum.map(fn {id, _} -> id end)
  end

  defp meeting_members(_, _, nil), do: []
  defp meeting_members(state, user_id, meeting) do
    state.members
    |> Enum.filter(fn {id, member} ->
      id != user_id and member.meeting == meeting
    end)
    |> Enum.map(fn {id, _} -> id end)
  end
end
