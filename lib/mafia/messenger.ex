defmodule Mafia.Messenger do
  alias Mafia.Types

  @spec send_text(Types.id(), String.t()) :: :ok
  def send_text(id, text) do
    adapter = Application.get_env(:mafia, :client_adapter)
    adapter.send_text(id, text)
    :ok
  end

  @spec send_text_to_many([Types.id()], String.t()) :: :ok
  def send_text_to_many(ids, text) do
    adapter = Application.get_env(:mafia, :client_adapter)
    Enum.each(ids, fn id ->
      adapter.send_text(id, text)
      Process.sleep(50)
    end)
  end
end
