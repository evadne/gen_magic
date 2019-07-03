defmodule GenMagicTest do
  use ExUnit.Case
  doctest GenMagic

  alias GenMagic.ApprenticeServer, as: Magic

  setup_all do
    {:ok, pid} = Magic.start_link()
    {:ok, %{pid: pid}}
  end

  test "Makefile is text file", %{pid: pid} do
    path = File.cwd!() |> Path.join("Makefile")

    assert {:ok, [mime_type: "text/x-makefile", encoding: _, content: _]} =
             GenServer.call(pid, {:perform, path})
  end
end
