defmodule Mafia.TimerTest do
  use ExUnit.Case
  doctest Mafia.Game.Timer

  @tag :timer_test
  test "타이머 실행" do
    Registry.start_link(keys: :unique, name: Mafia.Game.Timer.Registry)
    {:ok, _pid} = Mafia.Game.Timer.start_link(:test)

    Mafia.Game.Timer.reset(:test, 10_000)
    Mafia.Game.Timer.start(:test, %{
      5_000 => fn -> IO.puts("5초 남았습니다.") end,
      3_000 => fn -> IO.puts("3초 남았습니다.") end,
      2_000 => fn -> IO.puts("2초 남았습니다.") end,
      1_000 => fn -> IO.puts("1초 남았습니다.") end,
      :main => fn -> IO.puts("타이머가 종료되었습니다.") end
    })

    Process.sleep(5_500)
    Mafia.Game.Timer.extend(:test, 3_000)

    Process.sleep(3_500)
    Mafia.Game.Timer.reduce(:test, 1_000)

    Process.sleep(5_000)
  end
end
