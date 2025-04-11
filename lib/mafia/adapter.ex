defmodule Mafia.Adapter do
  alias Mafia.Types
  @callback send_text(id :: Types.id(), text :: String.t()) :: any()
  @callback send_image(id :: Types.id(), base64 :: String.t()) :: any()
end
