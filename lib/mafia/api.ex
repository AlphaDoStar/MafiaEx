defmodule Mafia.API do
  alias Mafia.Types

  @spec create_room(Types.id(), String.t()) ::
    {:ok, :success | :already_in_room} | {:error, :already_exists | term()}
  def create_room(user_id, user_name) do
    case Mafia.User.API.get_room(user_id) do
      :not_in_room ->
        case Mafia.Room.Supervisor.create_room(user_id, user_name) do
          {:ok, room_id} ->
            Mafia.User.API.join_room(user_id, room_id)

            message = "새로운 방 이름을 입력해 주세요."
            Mafia.Messenger.send_text(user_id, message)
            {:ok, :success}

          {:error, reason} ->
            send_error_message(user_id, reason)
        end

      room_id ->
        room_name =
          room_id
          |> Mafia.Room.API.name()
          |> shorten(10)

        message = "#{user_name} 님은 이미 #{room_name} 방에 참여 중입니다."
        Mafia.Messenger.send_text(user_id, message)
        {:ok, :already_in_room}
    end
  end

  @spec set_room_name(Types.id(), String.t()) ::
    {:ok, :success | :not_host} | {:error, :not_in_room}
  def set_room_name(user_id, room_name) do
    case Mafia.User.API.get_room(user_id) do
      :not_in_room ->
        message = "방에 입장하지 않은 상태입니다."
        Mafia.Messenger.send_text(user_id, message)
        {:error, :not_in_room}

      room_id ->
        if Mafia.Room.API.host?(room_id, user_id) do
          Mafia.Room.API.set_name(room_id, room_name)

          room_name = room_name |> shorten(4)
          message = "방 이름을 ⌈#{room_name}⌋(으)로\n설정하였습니다." # 조사 처리 필요
          Mafia.Messenger.send_text(user_id, message)
          {:ok, :success}
        else
          message = "관리자만 방 이름을 설정할 수 있습니다."
          Mafia.Messenger.send_text(user_id, message)
          {:ok, :not_host}
        end
    end
  end

  @spec join_room(Types.id(), Types.id(), String.t()) ::
    {:ok, :success} | {:error, :room_not_found | :already_in_room}
  def join_room(user_id, room_id, user_name) do
    case Mafia.User.API.get_room(user_id) do
      :not_in_room ->
        if Mafia.Room.Supervisor.room_exists?(room_id) do
          message = "#{user_name} 님이 입장했습니다."
          Mafia.Room.API.broadcast_message(room_id, message)

          Mafia.Room.API.add_member(room_id, user_id, user_name)
          Mafia.User.API.join_room(user_id, room_id)

          room_name = Mafia.Room.API.name(room_id)
          member_count = Mafia.Room.API.member_count(room_id)
          message = "#{room_name} 방에 입장했습니다.\n현재 인원: #{member_count}명"
          Mafia.Messenger.send_text(user_id, message)
          {:ok, :success}
        else
          message = "존재하지 않는 방입니다."
          Mafia.Messenger.send_text(user_id, message)
          {:error, :room_not_found}
        end

      room_id ->
        room_name = Mafia.Room.API.name(room_id)
        message = "#{user_name} 님은 이미 #{room_name} 방에 참여 중입니다."
        Mafia.Messenger.send_text(user_id, message)
        {:error, :already_in_room}
    end
  end

  @spec broadcast_user_message(Types.id(), String.t()) ::
    {:ok, :success} | {:error, :not_in_room}
  def broadcast_user_message(user_id, message) do
    case Mafia.User.API.get_room(user_id) do
      :not_in_room ->
        message = "방에 입장하지 않은 상태입니다."
        Mafia.Messenger.send_text(user_id, message)
        {:error, :not_in_room}

      room_id ->
        Mafia.Room.API.broadcast_member_message(room_id, user_id, message)
        {:ok, :success}
    end
  end

  def toggle_role_status(user_id, role_indices) when is_list(role_indices) do
    case Mafia.User.API.get_room(user_id) do
      :not_in_room ->
        message = "방에 입장하지 않은 상태입니다."
        Mafia.Messenger.send_text(user_id, message)
        {:error, :not_in_room}

      room_id ->
        cond do
          not Mafia.Room.API.host?(room_id, user_id) ->
            message = "관리자만 설정할 수 있습니다."
            Mafia.Messenger.send_text(user_id, message)
            {:ok, :not_host}

          Mafia.Room.API.game_started?(room_id) ->
            message = "게임 중에는 설정할 수 없습니다."
            Mafia.Messenger.send_text(user_id, message)
            {:ok, :game_started}

          not Enum.all?(role_indices, fn index ->
            is_integer(index) and
            index > 0 and
            index < length(Mafia.Game.Role.Manager.role_modules())  # except citizen
          end) ->
            message = "잘못된 입력입니다.\n올바른 번호를 입력해 주세요."
            Mafia.Messenger.send_text(user_id, message)
            {:ok, :invalid_input}

          true ->
            Mafia.Room.API.toggle_active_roles(room_id, role_indices)

            message = "직업 활성화 설정을 갱신했습니다."
            Mafia.Messenger.send_text(user_id, message)
            {:ok, :success}
        end
    end
  end

  def start_game(user_id) do
    case Mafia.User.API.get_room(user_id) do
      :not_in_room ->
        message = "방에 입장하지 않은 상태입니다."
        Mafia.Messenger.send_text(user_id, message)
        {:error, :not_in_room}

      room_id ->
        cond do
          not Mafia.Room.API.host?(room_id, user_id) ->
            message = "관리자만 게임을 시작할 수 있습니다."
            Mafia.Messenger.send_text(user_id, message)
            {:ok, :not_host}

          Mafia.Room.API.game_started?(room_id) ->
            message = "이미 게임이 시작되었습니다."
            Mafia.Messenger.send_text(user_id, message)
            {:error, :already_started}

          true ->
            with {:ok, :success} <- Mafia.Game.Supervisor.create_game(room_id),
                 {:ok, :success} <- Mafia.Game.Supervisor.create_timer(room_id) do
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
    case Mafia.User.API.get_room(user_id) do
      :not_in_room ->
        message = "방에 입장하지 않은 상태입니다."
        Mafia.Messenger.send_text(user_id, message)
        {:error, :not_in_room}

      room_id ->
        cond do
          not Mafia.Room.API.host?(room_id, user_id) ->
            message = "관리자만 위임할 수 있습니다."
            Mafia.Messenger.send_text(user_id, message)
            {:ok, :not_host}

          Mafia.User.API.get_room(target_id) !== room_id ->
            message = "현재 방에 속한 사람이 아닙니다."
            Mafia.Messenger.send_text(user_id, message)
            {:error, :target_not_in_room}

          true ->
            host_name = Mafia.Room.API.transfer_host(room_id, target_id)
            message = "#{host_name} 님이 관리자가 되었습니다."
            Mafia.Room.API.broadcast_message(room_id, message)
            {:ok, :success}
        end
    end
  end

  @spec leave_room(Types.id()) ::
    {:ok, :success | :cannot_leave_during_game | :host_cannot_leave} | {:error, :not_in_room}
  def leave_room(user_id) do
    case Mafia.User.API.get_room(user_id) do
      :not_in_room ->
        message = "방에 입장하지 않은 상태입니다."
        Mafia.Messenger.send_text(user_id, message)
        {:error, :not_in_room}

      room_id ->
        cond do
          Mafia.Room.API.member_count(room_id) === 1 ->
            Mafia.User.API.leave_room(user_id)

            room_name = Mafia.Room.API.name(room_id)
            message = "#{room_name} 방에서 퇴장했습니다."
            Mafia.Messenger.send_text(user_id, message)
            Mafia.Room.API.end_room(room_id)
            {:ok, :success}

          Mafia.Room.API.game_started?(room_id) ->
            message = "게임 중에는 퇴장할 수 없습니다."
            Mafia.Messenger.send_text(user_id, message)
            {:ok, :cannot_leave_during_game}

          Mafia.Room.API.host?(room_id, user_id) ->
            message = "관리자는 퇴장할 수 없습니다.\n다른 사람에게 위임해 주세요."
            Mafia.Messenger.send_text(user_id, message)
            {:ok, :host_cannot_leave}

          true ->
            room_name = Mafia.Room.API.name(room_id)
            message = "#{room_name} 방에서 퇴장했습니다."
            Mafia.Messenger.send_text(user_id, message)

            Mafia.User.API.leave_room(user_id)

            user_name = Mafia.Room.API.remove_member(room_id, user_id)
            message = "#{user_name} 님이 퇴장했습니다."
            Mafia.Room.API.broadcast_message(room_id, message)
            {:ok, :success}
        end
    end
  end

  defp send_error_message(user_id, reason) do
    message = "오류가 발생하였습니다.\n원인: #{reason}"
    Mafia.Messenger.send_text(user_id, message)
    {:error, reason}
  end

  defp shorten(text, length) when is_binary(text) do
    if String.length(text) > length,
      do: String.trim(String.slice(text, 0, length)) <> "...",
      else: text
  end

  defp begin_game(game_id) do
    Mafia.Game.Timer.reset(game_id, 3_000)
    Mafia.Game.Timer.start(game_id, %{
      3_000 => fn -> Mafia.Room.API.broadcast_message(game_id, "3") end,
      2_000 => fn -> Mafia.Room.API.broadcast_message(game_id, "2") end,
      1_000 => fn -> Mafia.Room.API.broadcast_message(game_id, "1") end,
      :main => fn ->
        Mafia.Room.API.broadcast_message(game_id, "게임이 시작되었습니다.")
        begin_day(game_id)
      end
    })
  end

  defp begin_day(game_id) do
    # Mafia.Game.API.begin_day(game_id)
    Mafia.Game.Timer.reset(game_id, 60_000)
    Mafia.Game.Timer.start(game_id, %{
      30_000 => fn -> Mafia.Room.API.broadcast_message(game_id, "투표까지 30초 남았습니다.") end,
      10_000 => fn -> Mafia.Room.API.broadcast_message(game_id, "투표까지 10초 남았습니다.") end,
      :main => fn ->
        # Mafia.Game.API.begin_vote(game_id)
        Mafia.Room.API.broadcast_message(game_id, "투표 시간이 되었습니다.")
      end
    })
  end
end
