defmodule Mafia.Game.Server do
  use GenServer
  alias Mafia.Game.{State, Role}

  @impl true
  @spec init(Mafia.Room.State.t()) :: {:ok, State.t()}
  def init(%Mafia.Room.State{} = state) do
    id = state.id
    settings = state.settings
    players =
      state.members
      |> Enum.map(&member_to_player/1)
      |> Map.new()

    {:ok, Mafia.Game.State.new(id, players, settings)}
  end

  @impl true
  def handle_call(:begin_game, _from, %State{} = state) do
    new_state = %State{state | players: assign_roles(state)}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:players, _from, %State{} = state) do
    {:reply, state.players, state}
  end

  @impl true
  def handle_call(:begin_day, _from, %State{} = state) do
    new_state =
      state
      |> Map.put(:day_count, state.day_count + 1)
      |> Map.put(:phase, :day)
      |> put_in([:phase_states, :day], %{})

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:day_count, _from, %State{} = state) do
    {:reply, state.day_count, state}
  end

  @impl true
  def handle_call(:process_day, _from, %State{} = state) do
    {:reply, game_over?(state.players), state}
  end

  @impl true
  def handle_call(:begin_discussion, _from, %State{} = state) do
    new_state =
      state
      |> Map.put(:phase, :discussion)
      |> put_in([:phase_states, :discussion], %{adjusted_time: %{}})

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:time_adjusted?, id}, _from, %State{} = state) do
    adjusted_time = get_in(state, [:phase_states, :discussion, :adjusted_time, id]) || false
    {:reply, adjusted_time, state}
  end

  @impl true
  def handle_call({:extend_time, id, ms}, _from, %State{} = state) do
    Mafia.Game.Timer.extend(state.id, ms)
    new_state = put_in(state, [:phase_states, :discussion, :adjusted_time, id], true)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:reduce_time, id, ms}, _from, %State{} = state) do
    Mafia.Game.Timer.reduce(state.id, ms)
    new_state = put_in(state, [:phase_states, :discussion, :adjusted_time, id], true)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:begin_vote, _from, %State{} = state) do
    candidates =
      state.players
      |> Enum.filter(fn {_id, player} -> player.alive end)
      |> Enum.with_index()
      |> Enum.map(fn {{id, _player}, index} -> {index, id} end)
      |> Map.new()

    vote =
      %{
        candidates: candidates,
        counts: %{},
        voted: %{},
        result: %{
          counts: [],
          tied: false
        }
      }

    new_state =
      state
      |> Map.put(:phase, :vote)
      |> put_in([:phase_states, :vote], vote)

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:candidates, _from, %State{} = state) do
    candidates = state.phase_states.vote.candidates
    {:reply, candidates, state}
  end

  @impl true
  def handle_call({:voted?, id}, _from, %State{} = state) do
    voted = get_in(state, [:phase_states, :vote, :voted, id]) || false
    {:reply, voted, state}
  end

  @impl true
  def handle_call({:vote, voter_id, 0}, _from, %State{} = state) do
    new_state = put_in(state, [:phase_states, :vote, :voted, voter_id], true)
    vote_count =
      new_state.phase_states.vote.counts
      |> Map.values()
      |> Enum.sum()

    {:reply, vote_count, new_state}
  end
  def handle_call({:vote, voter_id, index}, _from, %State{} = state) do
    target_id = get_in(state, [:phase_states, :vote, :candidates, index])
    new_state =
      state
      |> update_in([:phase_states, :vote, :counts, target_id], &((&1 || 0) + 1))
      |> put_in([:phase_states, :vote, :voted, voter_id], true)

    vote_count =
      new_state.phase_states.vote.counts
      |> Map.values()
      |> Enum.sum()

    {:reply, vote_count, new_state}
  end

  @impl true
  def handle_call(:process_vote, _from, %State{} = state) do
    voter_count = map_size(state.phase_states.vote.voted)
    vote_count =
      state.phase_states.vote.counts
      |> Map.values()
      |> Enum.sum()

    sorted_counts =
      state.phase_states.vote.counts
      |> Enum.sort_by(fn {_id, count} -> count end, :desc)
      |> Enum.map(fn {id, count} -> {state.players[id], count} end)

    first_count =
      case sorted_counts do
        [] -> 0
        [{_, count} | _] -> count
      end

    tied =
      sorted_counts
      |> Enum.count(fn {_player, count} -> count === first_count end)
      |> Kernel.>(1)

    skipped_count = voter_count - vote_count
    result =
      %{
        counts: sorted_counts,
        skipped: tied or skipped_count >= first_count,
        skipped_count: skipped_count
      }

    new_state = put_in(state.phase_states.vote.result, result)
    {:reply, result, new_state}
  end

  @impl true
  def handle_call(:begin_defense, _from, %State{} = state) do
    new_state = put_in(state.phase, :defense)
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:begin_judgment, _from, %State{} = state) do
    judgment =
      %{
        approval: 0,
        rejection: 0,
        judged: %{}
      }

    new_state =
      state
      |> Map.put(:phase, :judgment)
      |> put_in([:phase_states, :judgment], judgment)

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:judged?, id}, _from, %State{} = state) do
    judged = get_in(state, [:phase_states, :judgment, :judged, id]) || false
    {:reply, judged, state}
  end

  @impl true
  def handle_call({:judge, id, approved}, _from, %State{} = state) do
    new_state =
      case approved do
        true -> update_in(state.phase_states.judgment.approval, &(&1 + 1))
        false -> update_in(state.phase_states.judgment.rejection, &(&1 + 1))
      end
      |> put_in([:phase_states, :judgment, :judged, id], true)

    %{approval: approval, rejection: rejection} = new_state.phase_states.judgment
    total_votes = approval + rejection

    {:reply, total_votes, new_state}
  end

  @impl true
  def handle_call(:process_judgment, _from, %State{} = state) do
    %{approval: approval, rejection: rejection} = state.phase_states.judgment

    {message, new_state} =
      if approval > rejection do
        [{target, _} | _] = state.phase_states.vote.result.counts
        Role.kill_player(target.role, :judgment, target.id, state)
      else
        {nil, state}
      end

    result =
      game_over?(new_state.players)
      |> Map.put(:approval, approval)
      |> Map.put(:rejection, rejection)
      |> Map.put(:message, message)

    {:reply, result, new_state}
  end

  @impl true
  def handle_call(:begin_night, _from, %State{} = state) do
    night =
      %{
        targets: %{},
        result: %{
          message: "아무 일도 일어나지 않았습니다."
        }
      }

    new_state =
      state
      |> Map.put(:phase, :night)
      |> put_in([:phase_states, :night], night)

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:available_targets, id}, _from, %State{} = state) do
    available_targets =
      state
      |> get_in([:players, id, :role])
      |> Role.available_targets(:night)

    {:reply, available_targets, state}
  end

  @impl true
  def handle_call(:process_night, _from, %State{} = state) do
    new_state =
      state.phase_states.night.targets
      |> Enum.map(fn {module, id} -> {apply(module, :new, []), id} end)
      |> Enum.sort_by(fn {role, _id} -> Role.priority(role) end)
      |> Enum.reduce(state, fn {role, id}, state ->
        Role.resolve_ability(role, :night, id, state)
      end)

    result = new_state.phase_states.night.result
    {:reply, result, new_state}
  end

  defp member_to_player({id, %{name: name}}) do
    Mafia.Game.Player.new(id, name)
  end

  defp assign_roles(state) do
    case map_size(state.players) do
      5 -> assign_specific_roles(state, %{mafia: 1, lover: 2}, 5)
      10 -> assign_specific_roles(state, %{mafia: 2, lover: 2}, 10)
      count -> assign_specific_roles(state, %{mafia: 1, lover: 2}, count)
    end
  end

  defp assign_specific_roles(state, role_counts, count) do
    new_role_counts =
      case state.settings.mafia_count do
        nil -> role_counts
        count -> Map.put(role_counts, :mafia, count)
      end
      |> Enum.map(fn {role_atom, count} ->
        {Role.Manager.role_module_by_atom(role_atom), count}
      end)

    roles = generate_roles(state.settings.active_roles, new_role_counts, count) |> Enum.shuffle()

    [state.players, roles]
    |> Enum.zip()
    |> Enum.map(fn {{id, player}, role} -> {id, update_player_role(player, role)} end)
    |> Map.new()
  end

  defp generate_roles(role_setting, role_counts, count) do
    active_roles = role_setting |> Map.filter(fn {_role, active} -> active end) |> Map.keys()
    fixed_roles = for {role, count} <- role_counts, role in active_roles, _ <- 1..count, do: role
    rest_roles =
      role_setting
      |> Map.filter(fn {role, active} -> active and role not in active_roles end)
      |> Map.keys()
      |> Stream.concat(Stream.repeatedly(fn -> Role.Citizen end))
      |> Enum.take(count - length(fixed_roles))

    fixed_roles ++ rest_roles
  end

  defp update_player_role(player, role_module) do
    %{player | role: apply(role_module, :new, [])}
  end

  defp game_over?(players) do
    cond do
      citizen_win?(players) -> %{over: true, win: :citizen}
      mafia_win?(players) -> %{over: false, win: :mafia}
      true -> %{over: false, win: nil}
    end
  end

  defp citizen_win?(players) do
    Enum.all?(players, fn {_id, %{role: role}} ->
      Role.team(role) !== :mafia
    end)
  end

  defp mafia_win?(players) do
    mafia_count =
      players
      |> Enum.filter(fn {_id, %{role: role}} ->
        Role.team(role) === :mafia
      end)
      |> Enum.count()

    mafia_count * 2 >= map_size(players)
  end
end
