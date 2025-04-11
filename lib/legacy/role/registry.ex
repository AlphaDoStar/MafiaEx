defmodule Mafia.Role.Registry do
  defmacro __using__(_opts) do
    quote do
      @behaviour Mafia.Role.Ability

      Module.register_attribute(__MODULE__, :role_name, accumulate: false)
      Module.register_attribute(__MODULE__, :phase, accumulate: false)
      Module.register_attribute(__MODULE__, :priority, accumulate: false)  # 고민해 볼 것

      @before_compile Mafia.Role.Registry
    end
  end

  defmacro __before_compile__(env) do
    role_name = Module.get_attribute(env.module, :role_name)
    team = Module.get_attribute(env.module, :team)
    phase = Module.get_attribute(env.module, :phase)
    priority = Module.get_attribute(env.module, :priority)

    quote do
      @impl true
      def role_name, do: unquote(role_name)

      @impl true
      def team, do: unquote(team)

      @impl true
      def phase, do: unquote(phase)

      @impl true
      def priority, do: unquote(priority)
    end
  end

  @spec all_roles() :: list()
  def all_roles do
    :code.all_loaded()
    |> Enum.filter(fn {module, _loaded} ->
      module_name = to_string(module)
      String.starts_with?(module_name, "Elixir.Mafia.Role.") &&
      implements_behaviour?(module, Mafia.Role.Ability)
    end)
    |> Enum.map(fn {module, _loaded} -> module end)
  end

  defp implements_behaviour?(module, behaviour) do
    try do
      behaviours = module.module_info()[:attributes][:behaviour] || []
      behaviour in behaviours
    rescue
      _ -> false
    end
  end
end
