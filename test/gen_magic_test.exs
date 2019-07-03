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
             GenServer.call(pid, {:file, path})
  end

  @tag load: true, timeout: 180_000
  test "Load test local files", %{pid: pid} do
    "/usr/share/**/*"
    |> Path.wildcard()
    |> Stream.reject(&File.dir?/1)
    |> Stream.chunk_every(500)
    |> Stream.flat_map(&Enum.shuffle/1)
    |> Stream.cycle()
    |> Stream.take(10000)
    |> Stream.map(
      &assert {:ok, [mime_type: _, encoding: _, content: _]} = GenServer.call(pid, {:file, &1})
    )
    |> Enum.all?()
    |> assert
  end
end
