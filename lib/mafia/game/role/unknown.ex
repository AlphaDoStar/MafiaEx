defmodule Mafia.Game.Role.Unknown do
  defstruct [:name, :team, :targets]

  def new do
    %__MODULE__{
      name: :unknown,
      team: :neutral,
      targets: []
    }
  end
end

defimpl Mafia.Game.Role, for: Mafia.Game.Role.Unknown do
  def atom(_), do: :unknown
  def display_name(_), do: "알 수 없음"
  def target_list(_, _), do: []
  def perform_action(_, state, _), do: state
end
