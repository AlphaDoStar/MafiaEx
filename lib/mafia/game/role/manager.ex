defmodule Mafia.Game.Role.Manager do
  @moduledoc """
  마피아 게임 직업 관리 모듈
  """
  alias Mafia.Game.Role

  @role_modules [
    Role.Mafia,
    Role.Doctor,
    Role.Police
  ]

  @role_structs @role_modules
    |> Enum.map(&apply(&1, :new, []))

  @default_active_roles %{
    Role.Mafia => true,
    Role.Doctor => true,
    Role.Police => true
  }

  @spec role_modules() :: [module()]
  def role_modules, do: @role_modules

  @spec role_structs() :: [struct()]
  def role_structs, do: @role_structs

  @spec role_module_by_atom(atom()) :: module()
  def role_module_by_atom(atom) do
    module = Enum.find(@role_structs, fn struct ->
      Role.atom(struct) === atom
    end)

    if module, do: module.__struct__, else: Role.Unknown
  end

  @spec default_active_roles() :: %{module() => boolean()}
  def default_active_roles, do: @default_active_roles
end
