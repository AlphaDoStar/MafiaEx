defmodule Mafia.API do
  alias Mafia.{Game, Messenger, Room, User}

  def create_room(user_id, user_name) do
    case User.API.room_id(user_id) do
      nil ->
        case Room.Supervisor.create_room(user_id, user_name) do
          {:ok, room_id} ->
            User.API.join_room(user_id, room_id)
            Messenger.send_text(user_id, "새로운 방 이름을 입력해 주세요.")
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

  def set_room_name(user_id, room_name) do
    with_user_in_room(user_id, fn room_id ->
      cond do
        not Room.API.host?(room_id, user_id) ->
          Messenger.send_text(user_id, "관리자만 방 이름을 설정할 수 있습니다.")
          {:ok, :not_host}

        true ->
          Room.API.set_name(room_id, room_name)
          room_name = room_name |> shorten(4)
          message = "방 이름을 ⌈#{room_name}⌋(으)로\n설정하였습니다." # 조사 처리 필요
          Messenger.send_text(user_id, message)
          {:ok, :success}
      end
    end)
  end

  def join_room(user_id, room_id, user_name) do
    case User.API.room_id(user_id) do
      nil ->
        cond do
          not Room.Supervisor.room_exists?(room_id) ->
            Messenger.send_text(user_id, "존재하지 않는 방입니다.")
            {:error, :no_room}

          true ->
            message = "#{user_name} 님이 입장했습니다."
            Room.API.broadcast_message(room_id, message)

            Room.API.add_member(room_id, user_id, user_name)
            User.API.join_room(user_id, room_id)

            room_name = Room.API.name(room_id)
            member_count = Room.API.member_count(room_id)
            message = "#{room_name} 방에 입장했습니다.\n현재 인원: #{member_count}명"
            Messenger.send_text(user_id, message)
            {:ok, :success}
        end

      room_id ->
        room_name = Room.API.name(room_id)
        message = "#{user_name} 님은 이미 #{room_name} 방에 참여 중입니다."
        Messenger.send_text(user_id, message)
        {:error, :already_in_room}
    end
  end

  def transfer_host(user_id, target_id) do
    with_user_in_room(user_id, fn room_id ->
      cond do
        User.API.room_id(target_id) != room_id ->
          Messenger.send_text(user_id, "현재 방에 속한 사람이 아닙니다.")
          {:error, :no_target}

        not Room.API.host?(room_id, user_id) ->
          Messenger.send_text(user_id, "관리자만 위임할 수 있습니다.")
          {:ok, :not_host}

        true ->
          host_name = Room.API.transfer_host(room_id, target_id)
          message = "#{host_name} 님이 관리자가 되었습니다."
          Room.API.broadcast_message(room_id, message)
          {:ok, :success}
      end
    end)
  end

  def leave_room(user_id) do
    with_user_in_room(user_id, fn room_id ->
      cond do
        Room.API.member_count(room_id) == 1 ->
          User.API.leave_room(user_id)

          room_name = Room.API.name(room_id)
          message = "#{room_name} 방에서 퇴장했습니다."
          Messenger.send_text(user_id, message)
          Room.API.end_room(room_id)
          {:ok, :success}

        Room.API.game_started?(room_id) ->
          Messenger.send_text(user_id, "게임 중에는 퇴장할 수 없습니다.")
          {:ok, :not_allowed}

        Room.API.host?(room_id, user_id) ->
          message = "관리자는 퇴장할 수 없습니다.\n다른 사람에게 위임해 주세요."
          Messenger.send_text(user_id, message)
          {:ok, :not_allowed}

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
    end)
  end

  def broadcast_user_message(user_id, message) do
    with_user_in_room(user_id, fn room_id ->
      Room.API.broadcast_member_message(room_id, user_id, message)
      {:ok, :success}
    end)
  end

  def toggle_role_status(user_id, role_indices) when is_list(role_indices) do
    with_user_in_room(user_id, fn room_id ->
      cond do
        not Enum.all?(role_indices, fn index ->
          is_integer(index) and
          index > 0 and
          index < length(Game.Role.Manager.role_modules())
        end) ->
          Messenger.send_text(user_id, "올바른 번호를 입력해 주세요.")
          {:error, :invalid_input}

        not Room.API.host?(room_id, user_id) ->
          Messenger.send_text(user_id, "관리자만 설정할 수 있습니다.")
          {:ok, :not_host}

        Room.API.game_started?(room_id) ->
          Messenger.send_text(user_id, "게임 중에는 설정할 수 없습니다.")
          {:ok, :game_started}

        true ->
          Room.API.toggle_active_roles(room_id, role_indices)
          Messenger.send_text(user_id, "직업 활성화 설정을 갱신했습니다.")
          {:ok, :success}
      end
    end)
  end

  def create_game(user_id) do
    with_user_in_room(user_id, fn room_id ->
      cond do
        Room.API.game_started?(room_id) ->
          Messenger.send_text(user_id, "이미 게임이 시작되었습니다.")
          {:error, :already_started}

        not Room.API.host?(room_id, user_id) ->
          Messenger.send_text(user_id, "관리자만 게임을 시작할 수 있습니다.")
          {:ok, :not_host}

        true ->
          with {:ok, :success} <- Game.Supervisor.create_game(room_id),
               {:ok, :success} <- Game.Supervisor.create_timer(room_id) do
            begin_game(room_id)
            {:ok, :success}
          else
            {:error, reason} ->
              send_error_message(user_id, reason)
          end
      end
    end)
  end

  def extend_time(player_id) do
    with_user_in_room(player_id, fn game_id ->
      cond do
        not Game.API.alive?(game_id, player_id) ->
          Messenger.send_text(player_id, "당신은 사망했습니다.")
          {:ok, :not_alive}

        Game.API.phase(game_id) != :discussion ->
          Messenger.send_text(player_id, "토론 시간에만 시간을 조정할 수 있습니다.")
          {:ok, :not_discussion_phase}

        Game.API.time_adjusted?(game_id, player_id) ->
          Messenger.send_text(player_id, "이미 시간을 조정했습니다.")
          {:ok, :already_adjusted}

        true ->
          Game.API.extend_time(game_id, player_id, 10_000)
          Room.API.broadcast_message(game_id, "시간이 연장되었습니다.")
          {:ok, :success}
      end
    end)
  end

  def reduce_time(player_id) do
    with_user_in_room(player_id, fn game_id ->
      cond do
        not Game.API.alive?(game_id, player_id) ->
          Messenger.send_text(player_id, "당신은 사망했습니다.")
          {:ok, :not_alive}

        Game.API.phase(game_id) != :discussion ->
          Messenger.send_text(player_id, "토론 시간에만 시간을 조정할 수 있습니다.")
          {:ok, :not_discussion_phase}

        Game.API.time_adjusted?(game_id, player_id) ->
          Messenger.send_text(player_id, "이미 시간을 조정했습니다.")
          {:ok, :already_adjusted}

        Game.Timer.remaining(game_id) |> div(1_000) < 10 ->
          Messenger.send_text(player_id, "남은 시간이 10초 미만입니다.")
          {:ok, :nearly_expired}

        true ->
          Game.API.reduce_time(game_id, player_id, 10_000)
          Room.API.broadcast_message(game_id, "시간이 단축되었습니다.")
          {:ok, :success}
      end
    end)
  end

  def select(player_id, index) do
    with_user_in_room(player_id, fn game_id ->
      case Game.API.phase(game_id) do
        :vote -> vote(game_id, player_id, index)
        :night -> register_ability(game_id, player_id, index)
        _ -> {:ok, :not_allowed}
      end
    end)
  end

  def choice(player_id, choice) do
    with_user_in_room(player_id, fn game_id ->
      case Game.API.phase(game_id) do
        :judgment -> judge(game_id, player_id, choice)
        _ -> {:ok, :not_allowed}
      end
    end)
  end

  defp send_error_message(user_id, reason) do
    message = "오류가 발생하였습니다.\n원인: #{reason}"
    Messenger.send_text(user_id, message)
    {:error, reason}
  end

  defp with_user_in_room(user_id, fun) do
    case User.API.room_id(user_id) do
      nil ->
        Messenger.send_text(user_id, "방에 입장하지 않은 상태입니다.")
        {:error, :not_in_room}

      room_id ->
        fun.(room_id)
    end
  end

  defp shorten(text, length) when is_binary(text) do
    if String.length(text) > length do
      String.slice(text, 0, length) |> String.trim() |> Kernel.<>("...")
    else
      text
    end
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

    if day_count != 1 do
      night_message =
        case Game.API.process_night(game_id) do
          %{message: nil} -> "아무 일도 일어나지 않았습니다."
          %{message: message} -> message
        end

      Room.API.broadcast_message(game_id, night_message)
    end

    case Game.API.process_day(game_id) do
      %{over: true, win: win} -> game_over(game_id, win)
      %{over: false, win: nil} -> begin_discussion(game_id)
    end
  end

  defp begin_discussion(game_id) do
    Game.API.begin_discussion(game_id)

    alive_players =
      Game.API.players(game_id)
      |> Enum.filter(&alive?/1)
      |> Enum.map(&elem(&1, 0))

    Room.API.end_meetings(game_id)
    Room.API.create_meeting(game_id, :alive, alive_players)

    Game.Timer.reset(game_id, 60_000)
    Game.Timer.start(game_id, %{
      60_000 => fn -> Room.API.broadcast_message(game_id, "투표까지 60초 남았습니다.") end,
      30_000 => fn -> Room.API.broadcast_message(game_id, "30초 남았습니다.") end,
      10_000 => fn -> Room.API.broadcast_message(game_id, "10초 남았습니다.") end,
      5_000 => fn -> Room.API.broadcast_message(game_id, "5초 남았습니다.") end,
      :main => fn -> begin_vote(game_id) end
    })
  end

  defp begin_vote(game_id) do
    Game.API.begin_vote(game_id)
    Room.API.broadcast_message(game_id, "투표 시간이 되었습니다.")

    candidates =
      Game.API.candidates(game_id)
      |> Enum.map(fn {index, %{name: name}} -> "#{index}. #{name}" end)
      |> Enum.join("\n")

    Game.API.players(game_id)
    |> Enum.map(&alive?/1)
    |> Enum.each(fn {id, _player} ->
      Messenger.send_text(id, "0. 기권\n#{candidates}")
    end)

    Game.Timer.reset(game_id, 20_000)
    Game.Timer.start(game_id, %{
      20_000 => fn -> Room.API.broadcast_message(game_id, "20초 남았습니다.") end,
      5_000 => fn -> Room.API.broadcast_message(game_id, "5초 남았습니다.") end,
      :main => fn ->
        Room.API.broadcast_message(game_id, "투표가 종료되었습니다.")
        case Game.API.process_vote(game_id) do
          %{counts: []} ->
            Room.API.broadcast_message(game_id, "아무도 투표하지 않았습니다.")
            begin_night(game_id)

          %{skipped: true} = result ->
            Room.API.broadcast_message(game_id, format_vote_result(result), false)
            begin_night(game_id)

          %{counts: [{player, _count} | _]} = result ->
            Room.API.broadcast_message(game_id, format_vote_result(result), false)
            Room.API.broadcast_message(game_id, "#{player.name} 님이 처형대에 올랐습니다.")
            begin_defense(game_id)
        end
      end
    })
  end

  defp vote(game_id, player_id, index) do
    candidate_count =
      Game.API.candidates(game_id)
      |> Enum.count()

    cond do
      not Game.API.alive?(game_id, player_id) ->
        Messenger.send_text(player_id, "당신은 사망했습니다.")
        {:ok, :not_alive}

      Game.API.voted?(game_id, player_id) ->
        Messenger.send_text(player_id, "이미 투표했습니다.")
        {:ok, :already_voted}

      not is_integer(index) ->
        Messenger.send_text(player_id, "올바른 번호를 입력해 주세요.")
        {:ok, :invalid_index}

      index < 0 or index > candidate_count ->
        message = "0~#{candidate_count} 사이의 번호를 입력해 주세요."
        Messenger.send_text(player_id, message)
        {:ok, :invalid_index}

      true ->
        remaining_vote_count = Game.API.vote(game_id, player_id, index)

        player = Game.API.player(game_id, player_id)
        message = "#{player.name} 님이 투표했습니다."
        Room.API.broadcast_message(game_id, message)

        if remaining_vote_count == 0, do: Game.Timer.stop(game_id)
        {:ok, :success}
    end
  end

  defp format_vote_result(%{counts: []}), do: "투표 결과"
  defp format_vote_result(result) do
    result.counts
    |> Enum.map(fn {%{name: name}, count} ->
      check_marks = String.duplicate("✓", count)
      "#{name}  #{check_marks}"
    end)
    |> Enum.join("\n")
    |> then(fn string ->
      string <>
      if result.skipped_count > 0 do
        check_marks = String.duplicate("✓", result.skipped_count)
        "\n\n기권  #{check_marks}"
      else
        ""
      end
    end)
  end

  defp begin_defense(game_id) do
    Game.API.begin_defense(game_id)
    Room.API.broadcast_message(game_id, "최후의 변론을 시작하세요.")

    Game.Timer.reset(game_id, 20_000)
    Game.Timer.start(game_id, %{
      20_000 => fn -> Room.API.broadcast_message(game_id, "20초 남았습니다.") end,
      5_000 => fn -> Room.API.broadcast_message(game_id, "5초 남았습니다.") end,
      :main => fn -> begin_judgment(game_id) end
    })
  end

  defp begin_judgment(game_id) do
    Game.API.begin_judgment(game_id)
    Room.API.broadcast_message(game_id, "처형을 위한 찬반 투표 시간입니다.")

    Game.Timer.reset(game_id, 20_000)
    Game.Timer.start(game_id, %{
      20_000 => fn -> Room.API.broadcast_message(game_id, "20초 남았습니다.") end,
      5_000 => fn -> Room.API.broadcast_message(game_id, "5초 남았습니다.") end,
      :main => fn ->
        Room.API.broadcast_message(game_id, "투표가 종료되었습니다.")

        result = Game.API.process_judgment(game_id)
        approval_check_marks = String.duplicate("✓", result.approval)
        rejection_check_marks = String.duplicate("✓", result.rejection)

        message = "찬성  #{approval_check_marks}\n반대  #{rejection_check_marks}"
        Room.API.broadcast_message(game_id, message, false)

        case result do
          %{over: true, win: win, message: message} ->
            Room.API.broadcast_message(game_id, message)
            game_over(game_id, win)

          %{over: false, win: nil, message: message} ->
            Room.API.broadcast_message(game_id, message)
            begin_night(game_id)

          %{over: false, win: nil, message: nil} ->
            begin_night(game_id)
        end
      end
    })
  end

  defp judge(game_id, player_id, choice) do
    cond do
      not Game.API.alive?(game_id, player_id) ->
        Messenger.send_text(player_id, "당신은 사망했습니다.")
        {:ok, :not_alive}

      Game.API.judged?(game_id, player_id) ->
        Messenger.send_text(player_id, "이미 투표했습니다.")
        {:ok, :already_voted}

      choice not in [:yes, :no] ->
        Messenger.send_text(player_id, "잘못된 선택입니다.")
        {:ok, :invalid_choice}

      true ->
        remaining_vote_count = Game.API.judge(game_id, player_id, choice)

        player = Game.API.player(game_id, player_id)
        message = "#{player.name} 님이 투표했습니다."
        Room.API.broadcast_message(game_id, message)

        if remaining_vote_count == 0, do: Game.Timer.stop(game_id)
        {:ok, :success}
    end
  end

  defp begin_night(game_id) do
    Process.sleep(2_000)

    Game.API.begin_night(game_id)
    Room.API.broadcast_message(game_id, "밤이 되었습니다.")
    Room.API.end_meetings(game_id)

    players = Game.API.players(game_id)

    players
    |> Enum.filter(&alive?/1)
    |> Enum.group_by(&role_atom/1, &elem(&1, 0))
    |> Enum.each(fn {atom, players} ->
      Room.API.create_meeting(game_id, atom, players)
    end)

    players
    |> Enum.filter(&alive?/1)
    |> Enum.each(fn {id, %{role: role}} ->
      targets = Game.Role.available_targets(role, :night)
      if not Enum.empty?(targets) do
        message =
          targets
          |> Enum.map(fn {index, %{name: name}} -> "#{index}. #{name}" end)
          |> Enum.join("\n")

        Messenger.send_text(id, "능력 적용 대상을 입력해 주세요.")
        Messenger.send_text(id, message)
      end
    end)

    Game.Timer.reset(game_id, 40_000)
    Game.Timer.start(game_id, %{
      40_000 => fn -> Room.API.broadcast_message(game_id, "아침까지 40초 남았습니다.") end,
      10_000 => fn -> Room.API.broadcast_message(game_id, "10초 남았습니다.") end,
      :main => fn -> begin_day(game_id) end
    })
  end

  defp role_atom({_id, %{role: role}}), do: Game.Role.atom(role)

  defp register_ability(game_id, player_id, index) do
    target_count =
      Game.API.available_targets(game_id, player_id)
      |> Enum.count()

    cond do
      not Game.API.alive?(game_id, player_id) ->
        Messenger.send_text(player_id, "당신은 사망했습니다.")
        {:ok, :not_alive}

      target_count == 0 ->
        {:ok, :not_allowed}

      not is_integer(index) ->
        Messenger.send_text(player_id, "올바른 번호를 입력해 주세요.")
        {:ok, :invalid_index}

      index < 1 or index > target_count ->
        message = "1~#{target_count} 사이의 번호를 입력해 주세요."
        Messenger.send_text(player_id, message)
        {:ok, :invalid_index}

      true ->
        players = Game.API.players(game_id)
        atom = Game.Role.atom(players[player_id].role)
        message = Game.API.register_ability(game_id, player_id, index)

        players
        |> Enum.filter(fn {_id, %{role: role}} -> Game.Role.atom(role) == atom end)
        |> Enum.each(fn {id, _player} -> Messenger.send_text(id, message) end)

        {:ok, :success}
    end
  end

  defp game_over(game_id, win) do
    team_name =
      Game.Role.Manager.role_struct_by_atom(win)
      |> Game.Role.display_name()

    message =
      """
      게임이 종료되었습니다.
      #{team_name} 팀의 승리!
      """
      |> String.trim_trailing()

    Room.API.broadcast_message(game_id, message)
    Room.API.end_meetings(game_id)
    Game.API.end_game(game_id)
  end

  defp alive?({_id, %{alive: alive}}), do: alive
end
