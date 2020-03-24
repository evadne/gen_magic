defmodule GenMagicTest do
  use ExUnit.Case
  doctest GenMagic

  alias GenMagic.ApprenticeServer, as: Magic

  @iterations 10_000

  test "Makefile is text file" do
    {:ok, pid} = Magic.start_link([])
    path = makefile_path()

    assert {:ok, [mime_type: "text/x-makefile", encoding: _, content: _]} =
             GenServer.call(pid, {:file, path})
  end

  test "Top level helper function" do
    path = makefile_path()
    assert {:ok, [mime_type: "text/x-makefile", encoding: _, content: _]} = GenMagic.perform(path)
  end

  @tag load: true, timeout: 180_000
  test "Load test local files" do
    {:ok, pid} = Magic.start_link([])

    files_stream()
    |> Stream.cycle()
    |> Stream.take(@iterations)
    |> Stream.map(
      &assert {:ok, [mime_type: _, encoding: _, content: _]} = GenServer.call(pid, {:file, &1})
    )
    |> Enum.all?()
    |> assert
  end

  test "Non-existent file" do
    {:ok, pid} = Magic.start_link([])
    path = missing_filename()
    assert_no_file(GenServer.call(pid, {:file, path}))
  end

  test "Named process" do
    {:ok, _pid} = Magic.start_link(name: :gen_magic)
    path = makefile_path()

    assert {:ok, [mime_type: "text/x-makefile", encoding: _, content: _]} =
             GenServer.call(:gen_magic, {:file, path})
  end

  test "Custom database file recognises Elixir files" do
    database = Path.join(File.cwd!(), "priv/elixir.mgc")
    {:ok, pid} = Magic.start_link(database_patterns: [database])
    path = Path.join(File.cwd!(), "mix.exs")

    assert GenServer.call(pid, {:file, path}) ==
             {:ok,
              [
                mime_type: "text/x-elixir",
                encoding: "us-ascii",
                content: "Elixir module source text"
              ]}
  end

  @tag breaking: true, timeout: 180_000
  test "Load test local files and missing files" do
    {:ok, pid} = Magic.start_link([])

    files_stream()
    |> Stream.intersperse(missing_filename())
    |> Stream.cycle()
    |> Stream.take(@iterations)
    |> Stream.map(fn path ->
      case GenServer.call(pid, {:file, path}) do
        {:ok, [mime_type: _, encoding: _, content: _]} -> true
        {:error, "no_file"} -> true
      end
    end)
    |> Enum.all?()
    |> assert
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
      "/usr/share/**/*"
      |> Path.wildcard()
      |> Stream.reject(&File.dir?/1)
      |> Stream.chunk_every(500)
      |> Stream.flat_map(&Enum.shuffle/1)

  defp assert_no_file({:error, msg}) do
    assert msg == "no_file" || msg == "", msg
  end

  defp makefile_path, do: Path.join(File.cwd!(), "Makefile")
end
