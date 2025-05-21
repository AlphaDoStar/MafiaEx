defmodule Mafia.Adapter do
  alias Mafia.Game.Player
  @callback send_text(id :: Player.id(), text :: String.t()) :: term()
  @callback send_image(id :: Player.id(), base64 :: String.t()) :: term()
end
