defmodule GenMagic.PoollTest do
  use GenMagic.MagicCase

  test "pool" do
    {:ok, _} = GenMagic.Pool.start_link([name: TestPool, pool_size: 2])
    assert {:ok, _} = GenMagic.Pool.perform(TestPool, absolute_path("Makefile"))
    assert {:ok, _} = GenMagic.Pool.perform(TestPool, absolute_path("Makefile"))
    assert {:ok, _} = GenMagic.Pool.perform(TestPool, absolute_path("Makefile"))
    assert {:ok, _} = GenMagic.Pool.perform(TestPool, absolute_path("Makefile"))
    assert {:ok, _} = GenMagic.Pool.perform(TestPool, absolute_path("Makefile"))
    assert {:ok, _} = GenMagic.Pool.perform(TestPool, absolute_path("Makefile"))
    assert {:ok, _} = GenMagic.Pool.perform(TestPool, absolute_path("Makefile"))
    assert {:ok, _} = GenMagic.Pool.perform(TestPool, absolute_path("Makefile"))
    assert {:ok, _} = GenMagic.Pool.perform(TestPool, absolute_path("Makefile"))
  end

end
