defmodule Mafia.Game.State do
  use GenServer
  alias Mafia.Types

  @impl true
  @spec init([{:id, Types.id()}, {:players, %{Types.id() => Types.player()}}]) ::
    {:ok, Types.game_state()}
  def init(id: id, players: players) do
    {:ok, %{
      id: id,
      day_count: 1,
      phase: :day,
      players: players,
      pending_actions: %{}
    }}
  end

  @impl true
  def handle_call(:begin_day, _from, state) do
    # Mafia.Room.API.begin_day(state.room_id, state.players)

    new_state =
      %{
        state |
        day_count: state.day_count + 1,
        phase: :day,
        pending_actions: %{}
      }

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:process_night, _from, state) do
    # Mafia.Room.API.announce

    {:reply, :ok, state}
  end
end

%{
  day_count: 1,
  phase: :day,
  players: %{
    "id" => %{
      name: "user name",
      team: :mafia,
      role: :mafia,
      alive?: true,
      targets: []
    }
  },
  pending_actions: %{
    kill: "id",
    protect: "id"
  }
}
