defmodule GenMagic.ApprenticeTest do
  use GenMagic.MagicCase

  @tmp_path "/tmp/testgenmagicx"
  require Logger

  test "sends ready" do
    port = Port.open(GenMagic.Config.get_port_name(), GenMagic.Config.get_port_options([]))
    on_exit(fn() -> send(port, {self(), :close}) end)
    assert_ready(port)
  end

  test "stops" do
    port = Port.open(GenMagic.Config.get_port_name(), GenMagic.Config.get_port_options([]))
    on_exit(fn() -> send(port, {self(), :close}) end)
    assert_ready(port)
    send(port, {self(), {:command, :erlang.term_to_binary({:stop, :stop})}})
    assert_receive {^port, {:exit_status, 0}}
  end

  test "exits with no database" do
    opts = [:use_stdio, :binary, :exit_status, {:packet, 2}, {:args, []}]
    port = Port.open(GenMagic.Config.get_port_name(), opts)
    on_exit(fn() -> send(port, {self(), :close}) end)
    assert_receive {^port, {:exit_status, 1}}
  end

  test "exits with a non existent database" do
    opts = [
      {:args, ["--database-file", "/no/such/database"]},
      :use_stdio,
      :binary,
      :exit_status,
      {:packet, 2}
    ]

    port = Port.open(GenMagic.Config.get_port_name(), opts)
    on_exit(fn() -> send(port, {self(), :close}) end)
    assert_receive {^port, {:exit_status, 3}}
  end

  describe "port" do
    setup do
      port = Port.open(GenMagic.Config.get_port_name(), GenMagic.Config.get_port_options([]))
      on_exit(fn() -> send(port, {self(), :close}) end)
      assert_ready(port)
      %{port: port}
    end

    test "exits with badly formatted erlang terms", %{port: port} do
      send(port, {self(), {:command, "i forgot to term_to_binary!!"}})
      assert_receive {^port, {:exit_status, 5}}
    end

    test "errors with wrong command", %{port: port} do
      send(port, {self(), {:command, :erlang.term_to_binary(:wrong)}})
      assert_receive {^port, {:data, data}}
      assert {:error, :badarg} = :erlang.binary_to_term(data)
      refute_receive _

      send(port, {self(), {:command, :erlang.term_to_binary({:file, 42})}})
      assert_receive {^port, {:data, data}}
      assert {:error, :badarg} = :erlang.binary_to_term(data)
      refute_receive _

      send(port, {self(), {:command, :erlang.term_to_binary("more wrong")}})
      assert_receive {^port, {:data, data}}
      assert {:error, :badarg} = :erlang.binary_to_term(data)
      refute_receive _

      send(port, {self(), {:command, :erlang.term_to_binary({"no", "no"})}})
      assert_receive {^port, {:data, data}}
      assert {:error, :badarg} = :erlang.binary_to_term(data)
      refute_receive _
    end

    test "file works", %{port: port} do
      send(port, {self(), {:command, :erlang.term_to_binary({:file, Path.expand("Makefile")})}})
      assert_receive {^port, {:data, data}}
      assert {:ok, _} = :erlang.binary_to_term(data)
    end

    test "bytes works", %{port: port} do
      send(port, {self(), {:command, :erlang.term_to_binary({:bytes, "some bytes!"})}})
      assert_receive {^port, {:data, data}}
      assert {:ok, _} = :erlang.binary_to_term(data)
    end

    test "fails with non existent file", %{port: port} do
      send(port, {self(), {:command, :erlang.term_to_binary({:file, "/path/to/nowhere"})}})
      assert_receive {^port, {:data, data}}
      assert {:error, _} = :erlang.binary_to_term(data)
    end

    test "works with big file path", %{port: port} do
      # Test with longest valid path.
      {dir, bigfile} = too_big(@tmp_path, "/a")
      case File.mkdir_p(dir) do
        :ok ->
          File.touch!(bigfile)
          on_exit(fn -> File.rm_rf!(@tmp_path) end)
          send(port, {self(), {:command, :erlang.term_to_binary({:file, bigfile})}})
          assert_receive {^port, {:data, data}}
          assert {:ok, _} = :erlang.binary_to_term(data)
          refute_receive _

          # This path should be long enough for buffers, but larger than a valid path name.
          # Magic will return an errno 36.
          file = @tmp_path <> String.duplicate("a", 256)
          send(port, {self(), {:command, :erlang.term_to_binary({:file, file})}})
          assert_receive {^port, {:data, data}}
          assert {:error, {36, _}} = :erlang.binary_to_term(data)
          refute_receive _
          # Theses filename should be too big for the path buffer.
          file = bigfile <> "aaaaaaaaaa"
          send(port, {self(), {:command, :erlang.term_to_binary({:file, file})}})
          assert_receive {^port, {:data, data}}
          assert {:error, :enametoolong} = :erlang.binary_to_term(data)
          refute_receive _
          # This call should be larger than the COMMAND_BUFFER_SIZE. Ensure nothing bad happens!
          file = String.duplicate(bigfile, 4)
          send(port, {self(), {:command, :erlang.term_to_binary({:file, file})}})
          assert_receive {^port, {:data, data}}
          assert {:error, :badarg} = :erlang.binary_to_term(data)
          refute_receive _
          # We re-run a valid call to ensure the buffer/... haven't been corrupted in port land.
          send(port, {self(), {:command, :erlang.term_to_binary({:file, bigfile})}})
          assert_receive {^port, {:data, data}}
          assert {:ok, _} = :erlang.binary_to_term(data)
          refute_receive _
        {:error, :enametoolong} ->
          Logger.info("Skipping test, operating system does not support max POSIX length for directories")
          :ignore
      end
    end
  end

  def assert_ready(port) do
    assert_receive {^port, {:data, data}}
    assert :ready == :erlang.binary_to_term(data)
  end

  def too_big(path, filename, limit \\ 4095) do
    last_len = byte_size(filename)
    path_len = byte_size(path)
    needed = limit - (last_len + path_len)
    extra = make_too_big(needed, "")
    {path <> extra, path <> extra <> filename}
  end

  def make_too_big(needed, acc) when needed <= 255 do
    acc <> "/" <> String.duplicate("a", needed - 1)
  end

  def make_too_big(needed, acc) do
    acc = acc <> "/" <> String.duplicate("a", 254)
    make_too_big(needed - 255, acc)
  end
end
