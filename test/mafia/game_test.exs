defmodule Mafia.GameTest do
  use ExUnit.Case

  @tag :game_test
  @tag timeout: :infinity
  test "게임 실행" do
    Mafia.start_link(adapter: TestAdapter)

    Mafia.API.create_room("A", "윤아")
    Mafia.API.set_room_name("A", "아일릿 마피아")

    room_id = Mafia.User.API.room_id("A")

    Mafia.API.join_room("B", room_id, "민주")
    Mafia.API.join_room("C", room_id, "모카")
    Mafia.API.join_room("D", room_id, "원희")
    Mafia.API.join_room("E", room_id, "이로하")

    Mafia.API.broadcast_user_message("A", "다들 어서와")
    Mafia.API.broadcast_user_message("B", "안녕~~~")

    # assert Mafia.API.toggle_role_status("A", [2]) === {:ok, :success}
    assert Mafia.API.create_game("A") === {:ok, :success}

    receive do
      :never_comes -> :ok
    end
  end
end
