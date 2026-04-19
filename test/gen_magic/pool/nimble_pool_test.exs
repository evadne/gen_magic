defmodule GenMagic.Pool.NimblePoolTest do
  use GenMagic.MagicCase
  alias GenMagic.Pool.NimblePool, as: Pool

  describe "NimblePool" do
    test "can be started as part of a Supervisor" do
      children = [{Pool, pool_name: TestPool}]
      options = [strategy: :one_for_one, name: __MODULE__.Supervisor]
      Supervisor.start_link(children, options)
      assert_file(TestPool)
    end

    test "can be addressed by pid or name if started by name" do
      {:ok, pid} = Pool.start_link(pool_name: TestPool)
      assert_file(TestPool)
      assert_file(pid)
    end

    test "can be addressed by pid" do
      {:ok, pid} = Pool.start_link([])
      assert_file(pid)
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
