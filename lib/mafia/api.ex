defmodule Mafia.API do
  alias Mafia.{Game, Messenger, Room, User}
  alias Mafia.Types

  @spec create_room(Types.id(), String.t()) ::
    {:ok, :success | :already_in_room} | {:error, :already_exists | term()}
  def create_room(user_id, user_name) do
    case User.API.get_room(user_id) do
      :not_in_room ->
        case Room.Supervisor.create_room(user_id, user_name) do
          {:ok, room_id} ->
            User.API.join_room(user_id, room_id)

            message = "새로운 방 이름을 입력해 주세요."
            Messenger.send_text(user_id, message)
            {:ok, :success}

          {:error, reason} ->
            send_error_message(user_id, reason)
        end

      room_id ->
        room_name =
          room_id
          |> Room.API.name()
          |> shorten(10)

        message = "#{user_name} 님은 이미 #{room_name} 방에 참여 중입니다."
        Messenger.send_text(user_id, message)
        {:ok, :already_in_room}
    end
  end

  @spec set_room_name(Types.id(), String.t()) ::
    {:ok, :success | :not_host} | {:error, :not_in_room}
  def set_room_name(user_id, room_name) do
    case User.API.get_room(user_id) do
      :not_in_room ->
        message = "방에 입장하지 않은 상태입니다."
        Messenger.send_text(user_id, message)
        {:error, :not_in_room}

      room_id ->
        if Room.API.host?(room_id, user_id) do
          Room.API.set_name(room_id, room_name)

          room_name = room_name |> shorten(4)
          message = "방 이름을 ⌈#{room_name}⌋(으)로\n설정하였습니다." # 조사 처리 필요
          Messenger.send_text(user_id, message)
          {:ok, :success}
        else
          message = "관리자만 방 이름을 설정할 수 있습니다."
          Messenger.send_text(user_id, message)
          {:ok, :not_host}
        end
    end
  end

  @spec join_room(Types.id(), Types.id(), String.t()) ::
    {:ok, :success} | {:error, :room_not_found | :already_in_room}
  def join_room(user_id, room_id, user_name) do
    case User.API.get_room(user_id) do
      :not_in_room ->
        if Room.Supervisor.room_exists?(room_id) do
          message = "#{user_name} 님이 입장했습니다."
          Room.API.broadcast_message(room_id, message)

          Room.API.add_member(room_id, user_id, user_name)
          User.API.join_room(user_id, room_id)

          room_name = Room.API.name(room_id)
          member_count = Room.API.member_count(room_id)
          message = "#{room_name} 방에 입장했습니다.\n현재 인원: #{member_count}명"
          Messenger.send_text(user_id, message)
          {:ok, :success}
        else
          message = "존재하지 않는 방입니다."
          Messenger.send_text(user_id, message)
          {:error, :room_not_found}
        end

      room_id ->
        room_name = Room.API.name(room_id)
        message = "#{user_name} 님은 이미 #{room_name} 방에 참여 중입니다."
        Messenger.send_text(user_id, message)
        {:error, :already_in_room}
    end
  end

  @spec broadcast_user_message(Types.id(), String.t()) ::
    {:ok, :success} | {:error, :not_in_room}
  def broadcast_user_message(user_id, message) do
    case User.API.get_room(user_id) do
      :not_in_room ->
        message = "방에 입장하지 않은 상태입니다."
        Messenger.send_text(user_id, message)
        {:error, :not_in_room}

      room_id ->
        Room.API.broadcast_member_message(room_id, user_id, message)
        {:ok, :success}
    end
  end

  def toggle_role_status(user_id, role_indices) when is_list(role_indices) do
    case User.API.get_room(user_id) do
      :not_in_room ->
        message = "방에 입장하지 않은 상태입니다."
        Messenger.send_text(user_id, message)
        {:error, :not_in_room}

      room_id ->
        cond do
          not Room.API.host?(room_id, user_id) ->
            message = "관리자만 설정할 수 있습니다."
            Messenger.send_text(user_id, message)
            {:ok, :not_host}

          Room.API.game_started?(room_id) ->
            message = "게임 중에는 설정할 수 없습니다."
            Messenger.send_text(user_id, message)
            {:ok, :game_started}

          not Enum.all?(role_indices, fn index ->
            is_integer(index) and
            index > 0 and
            index < length(Game.Role.Manager.role_modules())  # except citizen
          end) ->
            message = "잘못된 입력입니다.\n올바른 번호를 입력해 주세요."
            Messenger.send_text(user_id, message)
            {:ok, :invalid_input}

          true ->
            Room.API.toggle_active_roles(room_id, role_indices)

            message = "직업 활성화 설정을 갱신했습니다."
            Messenger.send_text(user_id, message)
            {:ok, :success}
        end
    end
  end

  def start_game(user_id) do
    case User.API.get_room(user_id) do
      :not_in_room ->
        message = "방에 입장하지 않은 상태입니다."
        Messenger.send_text(user_id, message)
        {:error, :not_in_room}

      room_id ->
        cond do
          not Room.API.host?(room_id, user_id) ->
            message = "관리자만 게임을 시작할 수 있습니다."
            Messenger.send_text(user_id, message)
            {:ok, :not_host}

          Room.API.game_started?(room_id) ->
            message = "이미 게임이 시작되었습니다."
            Messenger.send_text(user_id, message)
            {:error, :already_started}

          true ->
            with {:ok, :success} <- Game.Supervisor.create_game(room_id),
                 {:ok, :success} <- Game.Supervisor.create_timer(room_id) do
              begin_game(room_id)
            else
              {:error, reason} ->
                send_error_message(user_id, reason)
            end
        end
    end
  end

  @spec transfer_host(Types.id(), Types.id()) ::
    {:ok, :success | :not_host} | {:error, :not_in_room | :target_not_in_room}
  def transfer_host(user_id, target_id) do
    case User.API.get_room(user_id) do
      :not_in_room ->
        message = "방에 입장하지 않은 상태입니다."
        Messenger.send_text(user_id, message)
        {:error, :not_in_room}

      room_id ->
        cond do
          not Room.API.host?(room_id, user_id) ->
            message = "관리자만 위임할 수 있습니다."
            Messenger.send_text(user_id, message)
            {:ok, :not_host}

          User.API.get_room(target_id) !== room_id ->
            message = "현재 방에 속한 사람이 아닙니다."
            Messenger.send_text(user_id, message)
            {:error, :target_not_in_room}

          true ->
            host_name = Room.API.transfer_host(room_id, target_id)
            message = "#{host_name} 님이 관리자가 되었습니다."
            Room.API.broadcast_message(room_id, message)
            {:ok, :success}
        end
    end
  end

  @spec leave_room(Types.id()) ::
    {:ok, :success | :cannot_leave_during_game | :host_cannot_leave} | {:error, :not_in_room}
  def leave_room(user_id) do
    case User.API.get_room(user_id) do
      :not_in_room ->
        message = "방에 입장하지 않은 상태입니다."
        Messenger.send_text(user_id, message)
        {:error, :not_in_room}

      room_id ->
        cond do
          Room.API.member_count(room_id) === 1 ->
            User.API.leave_room(user_id)

            room_name = Room.API.name(room_id)
            message = "#{room_name} 방에서 퇴장했습니다."
            Messenger.send_text(user_id, message)
            Room.API.end_room(room_id)
            {:ok, :success}

          Room.API.game_started?(room_id) ->
            message = "게임 중에는 퇴장할 수 없습니다."
            Messenger.send_text(user_id, message)
            {:ok, :cannot_leave_during_game}

          Room.API.host?(room_id, user_id) ->
            message = "관리자는 퇴장할 수 없습니다.\n다른 사람에게 위임해 주세요."
            Messenger.send_text(user_id, message)
            {:ok, :host_cannot_leave}

          true ->
            room_name = Room.API.name(room_id)
            message = "#{room_name} 방에서 퇴장했습니다."
            Messenger.send_text(user_id, message)

            User.API.leave_room(user_id)

            user_name = Room.API.remove_member(room_id, user_id)
            message = "#{user_name} 님이 퇴장했습니다."
            Room.API.broadcast_message(room_id, message)
            {:ok, :success}
        end
    end
  end

  defp send_error_message(user_id, reason) do
    message = "오류가 발생하였습니다.\n원인: #{reason}"
    Messenger.send_text(user_id, message)
    {:error, reason}
  end

  defp shorten(text, length) when is_binary(text) do
    if String.length(text) > length,
      do: String.trim(String.slice(text, 0, length)) <> "...",
      else: text
  end

  defp begin_game(game_id) do
    Game.Timer.reset(game_id, 3_000)
    Game.Timer.start(game_id, %{
      3_000 => fn -> Room.API.broadcast_message(game_id, "3") end,
      2_000 => fn -> Room.API.broadcast_message(game_id, "2") end,
      1_000 => fn -> Room.API.broadcast_message(game_id, "1") end,
      :main => fn ->
        Room.API.broadcast_message(game_id, "게임이 시작되었습니다.")

        Game.API.begin_game(game_id)
        Game.API.players(game_id)
        |> Enum.each(fn {id, player} ->
          display_name = Game.Role.display_name(player.role)
          message = "#{player.name} 님의 직업은 #{display_name}입니다."
          Messenger.send_text(id, message)
        end)

        begin_day(game_id)
      end
    })
  end

  defp begin_day(game_id) do
    Game.API.begin_day(game_id)

    day_count = Game.API.day_count(game_id)
    Room.API.broadcast_message(game_id, "#{day_count}번째 아침이 밝았습니다.")

    case Game.API.process_day(game_id) do
      %{over: true, win: win} -> game_over(game_id, win)
      %{over: false, win: nil} -> begin_discussion(game_id)
    end
  end

  defp begin_discussion(game_id) do
    Game.API.begin_discussion(game_id)

    {alive, dead} =
      Game.API.players(game_id)
      |> Enum.split_with(fn {_id, %{alive: alive}} -> alive end)

    alive_players = Enum.map(alive, fn {id, _player} -> id end)
    dead_players = Enum.map(dead, fn {id, _player} -> id end)

    Room.API.end_meetings(game_id)
    Room.API.create_meeting(game_id, :alive, alive_players)
    Room.API.create_meeting(game_id, :dead, dead_players)

    Game.Timer.reset(game_id, 60_000)
    Game.Timer.start(game_id, %{
      30_000 => fn -> Room.API.broadcast_message(game_id, "투표까지 30초 남았습니다.") end,
      10_000 => fn -> Room.API.broadcast_message(game_id, "투표까지 10초 남았습니다.") end,
      :main => fn -> begin_vote(game_id) end
    })
  end

  defp begin_vote(game_id) do
    Game.API.begin_vote(game_id)
    Room.API.broadcast_message(game_id, "투표 시간이 되었습니다.")

    Game.Timer.reset(game_id, 30_000)
    Game.Timer.start(game_id, %{
      10_000 => fn -> Room.API.broadcast_message(game_id, "10초 남았습니다.") end,
      5_000 => fn -> Room.API.broadcast_message(game_id, "5초 남았습니다.") end,
      :main => fn ->
        Room.API.broadcast_message(game_id, "투표가 종료되었습니다.")

        result = Game.API.process_vote(game_id)
        Room.API.broadcast_message(game_id, format_vote_result(result), false)

        case result do
          %{skipped: true} ->
            Room.API.broadcast_message(game_id, "아무도 죽지 않았습니다.")
            begin_night(game_id)

          %{counts: [{player, _count}]} ->
            Room.API.broadcast_message(game_id, "#{player.name} 님이 처형대에 올랐습니다.")
            begin_defense(game_id)
        end
      end
    })
  end

  defp format_vote_result(result) do
    result.counts
    |> Enum.map(fn {%{name: name}, count} ->
      check_marks = String.duplicate("✓", count)
      "#{name} #{check_marks}"
    end)
    |> Enum.join("\n")
    |> then(fn string ->
      string <>
      if result.skipped_count > 0 do
        check_marks = String.duplicate("✓", result.skipped_count)
        "\n\nSkip  #{check_marks}"
      else
        ""
      end
    end)
  end

  defp begin_defense(game_id) do
    Game.API.begin_defense(game_id)
  end

  defp begin_night(game_id) do
    Game.API.begin_night(game_id)
  end

  defp game_over(game_id, win) do
    team_name = Game.Role.display_name(win)
    message =
      """
      게임이 종료되었습니다.
      #{team_name} 팀의 승리!
      """
      |> String.trim_trailing()

    Room.API.broadcast_message(game_id, message)
    Room.API.end_meetings(game_id)
  end
end
