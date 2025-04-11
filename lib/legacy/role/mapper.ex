defmodule Mafia.Role.Mapper do
  @role_modules %{
    "마피아" => Mafia.Role.Mafia,
    "시민" => Mafia.Role.Citizen
  }

  def get_modules(role_name) do
    @role_modules[role_name] || Mafia.Role.Citizen
  end
end
