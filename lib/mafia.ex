defmodule Mafia do
  use Supervisor

  def start_link(opts) do
    adapter = Keyword.fetch!(opts, :adapter)
    Supervisor.start_link(__MODULE__, adapter, name: Mafia.Supervisor)
  end

  @impl true
  def init(adapter) when is_atom(adapter) do
    Application.put_env(:mafia, :client_adapter, adapter)

    children = [
      {Registry, keys: :unique, name: Mafia.Room.Registry},
      Mafia.User.API,
      Mafia.Room.Supervisor,
      # Mafia.Game.Supervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
