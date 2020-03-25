defmodule GenMagicTest do
  use ExUnit.Case
  doctest GenMagic

  alias GenMagic.ApprenticeServer, as: Apprentice

  @iterations 100

  test "Makefile is text file" do
    {:ok, pid} = Apprentice.start_link([])
    path = makefile_path()

    assert {:ok, [mime_type: "text/x-makefile", encoding: _, content: _]} =
             Apprentice.file(pid, path)
  end

  test "Top level helper function" do
    path = makefile_path()
    assert {:ok, [mime_type: "text/x-makefile", encoding: _, content: _]} = GenMagic.perform(path)
  end

  @tag load: true
  test "Load test local files" do
    {:ok, pid} = Apprentice.start_link([])

    files_stream()
    |> Stream.cycle()
    |> Stream.take(@iterations)
    |> Stream.map(
      &assert {:ok, [mime_type: _, encoding: _, content: _]} = Apprentice.file(pid, &1)
    )
    |> Enum.all?()
    |> assert
  end

  @tag :ci
  test "Non-existent file" do
    Process.flag(:trap_exit, true)
    {:ok, pid} = Apprentice.start_link([])
    path = missing_filename()
    assert_no_file(GenServer.call(pid, {:file, path}))
  end

  test "Named process" do
    {:ok, _pid} = Apprentice.start_link(name: :gen_magic)
    path = makefile_path()

    assert {:ok, [mime_type: "text/x-makefile", encoding: _, content: _]} =
             Apprentice.file(:gen_magic, path)
  end

  @tag :ci
  test "Custom database file recognises Elixir files" do
    database = Path.join(File.cwd!(), "test/elixir.mgc")
    {:ok, pid} = Apprentice.start_link(database_patterns: [database])
    path = Path.join(File.cwd!(), "mix.exs")

    assert Apprentice.file(pid, path) ==
             {:ok,
              [
                mime_type: "text/x-elixir",
                encoding: "us-ascii",
                content: "Elixir module source text"
              ]}
  end

  defp missing_filename do
    f =
      make_ref()
      |> inspect
      |> String.replace(~r/\D/, "")

    Path.join("/tmp", f)
  end

  defp files_stream,
    do:
      Path.join(File.cwd!(), "deps/**/*")
      |> Path.wildcard()
      |> Stream.reject(&File.dir?/1)
      |> Stream.chunk_every(10)
      |> Stream.flat_map(&Enum.shuffle/1)

  defp assert_no_file({:error, msg}) do
    assert msg == "no_file" || msg == "", msg
  end

  defp makefile_path, do: Path.join(File.cwd!(), "Makefile")
end
