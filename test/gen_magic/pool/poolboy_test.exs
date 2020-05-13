defmodule GenMagic.Pool.PoolboyTest do
  use GenMagic.MagicCase
  alias GenMagic.Pool.Poolboy, as: Pool

  describe "Poolboy" do
    test "can be addressed by name if started by name" do
      {:ok, _} = Pool.start_link(pool_name: TestPool)
      assert_file(TestPool)
    end

    test "can not be started without pool_name" do
      assert_raise ArgumentError, "pool_name must be set", fn ->
        Pool.start_link([])
      end
    end

    test "works concurrently" do
      {:ok, _} = Pool.start_link(pool_name: TestPool, pool_size: 2)
      parent_pid = self()

      for _ <- 1..10 do
        spawn(fn ->
          for _ <- 1..10 do
            assert_file(TestPool)
          end

          send(parent_pid, :ok)
        end)
      end

      for _ <- 1..10 do
        assert_receive :ok, 5000
      end
    end
  end

  defp assert_file(pool), do: assert_file(pool, absolute_path("Makefile"))
  defp assert_file(pool, path), do: assert({:ok, _} = Pool.perform(pool, path, []))
end
