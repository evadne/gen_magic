defmodule GenMagic.ServerTest do
  use GenMagic.MagicCase
  doctest GenMagic.Server

  describe "recycle_threshold" do
    test "resets" do
      {:ok, pid} = GenMagic.Server.start_link(recycle_threshold: 3)
      path = absolute_path("Makefile")
      assert :ok = assert_cycles(pid, 0)
      assert {:ok, _} = GenMagic.Server.perform(pid, path)
      assert :ok = assert_cycles(pid, 1)
      assert {:ok, _} = GenMagic.Server.perform(pid, path)
      assert :ok = assert_cycles(pid, 2)
      assert {:ok, _} = GenMagic.Server.perform(pid, path)
      assert :ok = assert_cycles(pid, 0)
    end

    test "resets before reply" do
      {:ok, pid} = GenMagic.Server.start_link(recycle_threshold: 1)
      path = absolute_path("Makefile")
      assert :ok = assert_cycles(pid, 0)
      assert {:ok, _} = GenMagic.Server.perform(pid, path)
      assert :ok = assert_cycles(pid, 0)
      assert {:ok, _} = GenMagic.Server.perform(pid, path)
      assert :ok = assert_cycles(pid, 0)
      assert {:ok, _} = GenMagic.Server.perform(pid, path)
      assert :ok = assert_cycles(pid, 0)
    end
  end

  defp assert_cycles(pid, count, retries \\ 5)

  defp assert_cycles(_pid, _count, 0) do
    :error
  end

  defp assert_cycles(pid, count, retries) do
    {:ok, status} = GenMagic.Server.status(pid)

    case status do
      %{cycles: ^count} -> :ok
      %{cycles: _} -> assert_cycles(pid, count, retries - 1)
    end
  end
end
