defmodule Mafia.GameAdapter do
  @behaviour Mafia.Adapter

  def send_text(id, text) do
    IO.puts("(#{id})\n#{text}\n")
  end

  def send_image(id, image) do
    IO.puts("(#{id}) #{image}")
  end
end

defmodule Mafia.GameTest do
  use ExUnit.Case

  @tag :game_test
  @tag timeout: :infinity
  test "게임 실행" do
    Mafia.start_link(adapter: Mafia.GameAdapter)

    Mafia.API.create_room("A", "윤아")
    Mafia.API.set_room_name("A", "아일릿 마피아")

    Mafia.API.join_room("B", 1, "민주")
    Mafia.API.join_room("C", 1, "모카")
    Mafia.API.join_room("D", 1, "원희")
    Mafia.API.join_room("E", 1, "이로하")

    Mafia.API.broadcast_user_message("A", "다들 어서와")
    Mafia.API.broadcast_user_message("B", "안녕~~~")

    Mafia.API.toggle_role_status("A", [2])
    Mafia.API.create_game("A")

    Process.sleep(3_000)
    Process.sleep(3_000)
    Mafia.API.reduce_time("A")
    Mafia.API.reduce_time("B")
    Mafia.API.reduce_time("C")
    Mafia.API.reduce_time("D")
    Mafia.API.reduce_time("E")

    Process.sleep(10_000)
    Mafia.API.reduce_time("A")
    Mafia.API.select("A", 0)
    Mafia.API.select("B", 1)
    Mafia.API.select("C", 2)
    Mafia.API.select("D", 3)

    Process.sleep(5_000)
    Mafia.API.select("E", 3)

    Process.sleep(3_000)
    Mafia.API.broadcast_user_message("C", "아니 왜 난데")
    Mafia.API.broadcast_user_message("D", "I like you")

    Process.sleep(20_000)
    Mafia.API.choice("A", :yes)
    Mafia.API.choice("A", :yes)
    Mafia.API.choice("B", :yes)
    Mafia.API.choice("C", :yes)
    Mafia.API.choice("D", :no)
    Mafia.API.choice("E", :no)

    Process.sleep(3_000)
    Process.sleep(2_000)
    Mafia.API.select("A", 1)
    Mafia.API.select("B", 1)
    Mafia.API.select("C", 1)
    Mafia.API.select("D", 1)
    Mafia.API.select("E", 1)

    receive do
      :never_comes -> :ok
    end
  end
end
