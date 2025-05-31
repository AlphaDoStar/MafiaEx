defmodule Mafia.Game.API do
  alias Mafia.Game.{Player, State}

  def start_link(%Mafia.Room.State{} = state) do
    GenServer.start_link(Mafia.Game.Server, state, name: via_tuple(state.id))
  end

  def begin_game(game_id) do
    GenServer.call(via_tuple(game_id), :begin_game)
  end

  def phase(game_id) do
    GenServer.call(via_tuple(game_id), :phase)
  end

  @spec players(State.id()) :: State.players()
  def players(game_id) do
    GenServer.call(via_tuple(game_id), :players)
  end

  @spec alive?(State.id(), Player.id()) :: boolean()
  def alive?(game_id, player_id) do
    GenServer.call(via_tuple(game_id), {:alive?, player_id})
  end

  @spec player(State.id(), Player.id()) :: Player.t()
  def player(game_id, player_id) do
    GenServer.call(via_tuple(game_id), {:player, player_id})
  end

  def begin_day(game_id) do
    GenServer.call(via_tuple(game_id), :begin_day)
  end

  def day_count(game_id) do
    GenServer.call(via_tuple(game_id), :day_count)
  end

  def process_day(game_id) do
    GenServer.call(via_tuple(game_id), :process_day)
  end

  def begin_discussion(game_id) do
    GenServer.call(via_tuple(game_id), :begin_discussion)
  end

  def time_adjusted?(game_id, player_id) do
    GenServer.call(via_tuple(game_id), {:time_adjusted?, player_id})
  end

  def extend_time(game_id, player_id, ms) do
    GenServer.call(via_tuple(game_id), {:extend_time, player_id, ms})
  end

  def reduce_time(game_id, player_id, ms) do
    GenServer.call(via_tuple(game_id), {:reduce_time, player_id, ms})
  end

  def begin_vote(game_id) do
    GenServer.call(via_tuple(game_id), :begin_vote)
  end

  def candidates(game_id) do
    GenServer.call(via_tuple(game_id), :candidates)
  end

  def voted?(game_id, player_id) do
    GenServer.call(via_tuple(game_id), {:voted?, player_id})
  end

  def vote(game_id, player_id, index) do
    GenServer.call(via_tuple(game_id), {:vote, player_id, index})
  end

  def process_vote(game_id) do
    GenServer.call(via_tuple(game_id), :process_vote)
  end

  def begin_defense(game_id) do
    GenServer.call(via_tuple(game_id), :begin_defense)
  end

  def begin_judgment(game_id) do
    GenServer.call(via_tuple(game_id), :begin_judgment)
  end

  def judged?(game_id, player_id) do
    GenServer.call(via_tuple(game_id), {:judged?, player_id})
  end

  def judge(game_id, player_id, approved) do
    GenServer.call(via_tuple(game_id), {:judge, player_id, approved})
  end

  def process_judgment(game_id) do
    GenServer.call(via_tuple(game_id), :process_judgment)
  end

  def begin_night(game_id) do
    GenServer.call(via_tuple(game_id), :begin_night)
  end

  def available_targets(game_id, player_id) do
    GenServer.call(via_tuple(game_id), {:available_targets, player_id})
  end

  def register_ability(game_id, player_id, index) do
    GenServer.call(via_tuple(game_id), {:register_ability, player_id, index})
  end

  def process_night(game_id) do
    GenServer.call(via_tuple(game_id), :process_night)
  end

  def end_game(game_id) do
    GenServer.call(via_tuple(game_id), :end_game)
  end

  defp via_tuple(game_id) do
    {:via, Registry, {Mafia.Game.Registry, game_id}}
  end
end
