defmodule GenMagic.ServerTest do
  use GenMagic.MagicCase
  doctest GenMagic.Server

  describe "recycle_threshold" do
    test "resets" do
      {:ok, pid} = GenMagic.Server.start_link(recycle_threshold: 3)
      path = absolute_path("Makefile")
      assert {:ok, %{cycles: 0}} = GenMagic.Server.status(pid)
      assert {:ok, _} = GenMagic.Server.perform(pid, path)
      assert {:ok, %{cycles: 1}} = GenMagic.Server.status(pid)
      assert {:ok, _} = GenMagic.Server.perform(pid, path)
      assert {:ok, %{cycles: 2}} = GenMagic.Server.status(pid)
      assert {:ok, _} = GenMagic.Server.perform(pid, path)
      Process.sleep(100)
      assert {:ok, %{cycles: 0}} = GenMagic.Server.status(pid)
    end

    test "resets before reply" do
      {:ok, pid} = GenMagic.Server.start_link(recycle_threshold: 1)
      path = absolute_path("Makefile")
      assert {:ok, %{cycles: 0}} = GenMagic.Server.status(pid)
      assert {:ok, _} = GenMagic.Server.perform(pid, path)
      Process.sleep(100)
      assert {:ok, %{cycles: 0}} = GenMagic.Server.status(pid)
      assert {:ok, _} = GenMagic.Server.perform(pid, path)
      Process.sleep(100)
      assert {:ok, %{cycles: 0}} = GenMagic.Server.status(pid)
      assert {:ok, _} = GenMagic.Server.perform(pid, path)
      Process.sleep(100)
      assert {:ok, %{cycles: 0}} = GenMagic.Server.status(pid)
    end
  end

  test "recycle" do
    {:ok, pid} = GenMagic.Server.start_link([])
    path = absolute_path("Makefile")
    assert {:ok, %{cycles: 0}} = GenMagic.Server.status(pid)
    assert {:ok, _} = GenMagic.Server.perform(pid, path)
    assert {:ok, %{cycles: 1}} = GenMagic.Server.status(pid)
    assert :ok = GenMagic.Server.recycle(pid)
    assert {:ok, %{cycles: 0}} = GenMagic.Server.status(pid)
  end
end
