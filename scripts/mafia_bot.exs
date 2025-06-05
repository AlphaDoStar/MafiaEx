Mix.install([
  {:iris_ex, git: "https://github.com/AlphaDoStar/IrisEx.git", tag: "v0.3.3"},
  # {:iris_ex, path: "../IrisEx"},
  {:mafia, path: "."}
])

defmodule Client.Application do
  use IrisEx.Application,
    bots: [Client.Bot],
    extensions: [:room_type],
    ws_url: "ws://192.168.0.17:3000/ws",
    http_url: "http://192.168.0.17:3000",
    children: [{Mafia, [adapter: Client.Adapter]}]
end

defmodule Client.Adapter do
  @behaviour Mafia.Adapter

  @impl true
  def send_text(room_id, text) do
    IrisEx.Client.send_text(room_id, text)
  end

  @impl true
  def send_image(room_id, base64) do
    IrisEx.Client.send_image(room_id, base64)
  end
end

defmodule Client.Bot do
  use IrisEx.Bot

  on :message do
    match "마피아" do
      reply("누구일까 마.피.아")
    end

    if direct_chat?(chat) do
      user_id = chat.room.id
      set user_id

      state :default do
        match "마피아 생성" do
          case Mafia.API.create_room(user_id, chat.sender.name) do
            :handled ->
              reply("방 이름을 입력해 주세요.")
              trans :naming

            :rejected -> :ok
            :ignored -> :ok
          end
        end

        match "마피아 입장" do
          rooms = Mafia.API.list_rooms()
          cond do
            Enum.empty?(rooms) ->
              reply("⌈마피아 생성⌋ 명령어로 방을 생성하세요.")

            true ->
              text =
                rooms
                |> Enum.map(fn {name, index} -> "#{index}. #{name}" end)
                |> Enum.join("\n")

              reply("방 번호를 입력해 주세요.")
              reply(text)
              trans :entrance
          end
        end
      end

      state :naming do
        case Mafia.API.set_room_name(user_id, chat.message.content) do
          :handled -> trans :lobby
          :rejected -> trans :default
          :ignored -> trans :default
        end
      end

      state :entrance do
        match ~r/^(\d+)$/ do
          [index] = args
          index = String.to_integer(index)
          case Mafia.API.join_room(user_id, index, chat.sender.name) do
            :handled -> trans :lobby
            :rejected -> :ok
            :ignored -> trans :default
          end
        end
      end

      state :lobby do
        match "마피아 퇴장" do
          case Mafia.API.leave_room(user_id) do
            :handled -> trans :default
            :rejected -> :ok
            :ignored -> continue()
          end
        end

        match "마피아 시작" do
          case Mafia.API.create_game(user_id) do
            :handled -> :ok
            :rejected -> :ok
            :ignored -> continue()
          end
        end

        match "시간 연장" do
          case Mafia.API.extend_time(user_id) do
            :handled -> :ok
            :rejected -> :ok
            :ignored -> continue()
          end
        end

        match "시간 단축" do
          case Mafia.API.reduce_time(user_id) do
            :handled -> :ok
            :rejected -> :ok
            :ignored -> continue()
          end
        end

        match ~r/^찬성?$/u do
          case Mafia.API.choice(user_id, :yes) do
            :handled -> :ok
            :rejected -> :ok
            :ignored -> continue()
          end
        end

        match ~r/^반대?$/u do
          case Mafia.API.choice(user_id, :no) do
            :handled -> :ok
            :rejected -> :ok
            :ignored -> continue()
          end
        end

        match ~r/^(\d+)$/ do
          [choice] = args
          index = String.to_integer(choice)
          case Mafia.API.select(user_id, index) do
            :handled -> :ok
            :rejected -> :ok
            :ignored -> continue()
          end
        end

        fallback do
          Mafia.API.broadcast_user_message(user_id, chat.message.content)
        end
      end
    end
  end

  defp direct_chat?(chat) do
    chat.room.type in ["DirectChat", "OD"]
  end
end

Client.Application.start(:normal, [])

receive do
  :never_comes -> :ok
end
