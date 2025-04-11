defmodule TestAdapter do
  @behaviour Mafia.Adapter

  def send_text(id, text) do
    # send(self(), {:send_text, id, text})
    IO.puts("(#{id}) #{text}")
  end

  def send_image(id, image) do
    # send(self(), {:send_image, id, image})
    IO.puts("(#{id}) #{image}")
  end
end

defmodule MafiaTest do
  use ExUnit.Case, async: false
  doctest Mafia

  # 공유 설정
  setup do
    Process.sleep(100)
    {:ok, pid} = Mafia.start_link(adapter: TestAdapter)
    on_exit(fn -> Application.delete_env(:mafia, :client_adapter) end)
    {:ok, supervisor_pid: pid}
  end

  @tag :test_1
  test "슈퍼바이저 실행", %{supervisor_pid: pid} do
    assert Process.alive?(pid)

    children = Supervisor.which_children(Mafia.Supervisor)

    assert Enum.any?(children, fn {id, _, _, _} -> id == Mafia.User end)
    assert Enum.any?(children, fn {id, _, _, _} -> id == Mafia.Room.Supervisor end)

    assert Application.get_env(:mafia, :client_adapter) == TestAdapter
  end

  @tag :test_2
  test "방 생성 및 이름 설정" do
    assert Mafia.API.create_room("001", "AlphaDo") === {:ok, :success}

    room_id = Mafia.User.API.get_room("001")
    assert room_id !== :not_in_room

    assert Mafia.Room.Supervisor.room_exists?(room_id)
    assert Mafia.Room.API.is_host?(room_id, "001")

    assert Mafia.API.set_room_name("001", "테스트 방") === {:ok, :success}

    Mafia.Room.Supervisor.get_all_room_ids()
    |> IO.inspect(pretty: true)

    Mafia.Room.Supervisor.get_all_room_names()
    |> IO.inspect(pretty: true)
  end

  @tag :test_3
  test "방 참여 로직" do
    Mafia.API.create_room("001", "AlphaDo")
    Mafia.API.set_room_name("001", "테스트 방")

    room_id = Mafia.User.API.get_room("001")

    assert Mafia.API.join_room("001", room_id, "AlphaDo") === {:error, :already_in_room}
    assert Mafia.API.join_room("002", room_id, "원희") === {:ok, :success}
    assert Mafia.API.join_room("003", room_id, "샌즈") === {:ok, :success}
  end

  @tag :test_4
  test "메시지 브로드캐스트" do
    Mafia.API.create_room("001", "AlphaDo")
    Mafia.API.set_room_name("001", "테스트 방")

    room_id = Mafia.User.API.get_room("001")
    Mafia.API.join_room("002", room_id, "원희")
    Mafia.API.join_room("003", room_id, "샌즈")

    Mafia.API.broadcast_user_message("001", "나는 AlphaDo")
    Mafia.API.broadcast_user_message("002", "나는 원희")
    Mafia.API.broadcast_user_message("003", "나는 샌즈")
  end

  @tag :test_5
  test "방장 권한 및 방장 이전" do
    Mafia.API.create_room("001", "AlphaDo")
    Mafia.API.set_room_name("001", "테스트 방")

    room_id = Mafia.User.API.get_room("001")
    Mafia.API.join_room("002", room_id, "원희")

    # 방장만 방 이름 변경 가능
    assert Mafia.API.set_room_name("001", "ILLIT and GLLIT") === {:ok, :success}
    assert Mafia.API.set_room_name("002", "원희가 세상을 지배한다") === {:ok, :not_host}

    # 방장은 퇴장 불가
    assert Mafia.API.leave_room("001") === {:ok, :host_cannot_leave}

    # 방장 위임 후 나가기 가능
    assert Mafia.API.transfer_host("001", "002") === {:ok, :success}
    assert Mafia.API.leave_room("001") === {:ok, :success}
  end

  @tag :test_6
  test "방 삭제 로직" do
    Mafia.API.create_room("001", "AlphaDo")
    Mafia.API.set_room_name("001", "테스트 방")

    room_id = Mafia.User.API.get_room("001")
    Mafia.API.join_room("002", room_id, "원희")

    # 방장 위임
    Mafia.API.transfer_host("001", "002")
    Mafia.API.leave_room("001")

    # 마지막 사용자가 나가면 방 삭제
    assert Mafia.Room.Supervisor.room_exists?(room_id)
    assert Mafia.API.leave_room("002") == {:ok, :success}
    refute Mafia.Room.Supervisor.room_exists?(room_id)
  end
end
