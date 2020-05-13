if Code.ensure_loaded?(NimblePool) do
  defmodule GenMagic.Pool.NimblePool do
    @moduledoc "Generic module providing pooling of `GenMagic.Server` by using NimblePool"
    @behaviour GenMagic.Pool
    @behaviour NimblePool

    @impl GenMagic.Pool
    def start_link(options) do
      {pool_size, pool_options} = Keyword.pop(options, :pool_size, System.schedulers_online())
      NimblePool.start_link(worker: {__MODULE__, pool_options}, pool_size: pool_size)
    end

    @impl GenMagic.Pool
    def perform(pool, path, options) do
      timeout = Keyword.get(options, :timeout, 5000)
      perform_fun = fn _, server -> {GenMagic.Server.perform(server, path, timeout), server} end
      NimblePool.checkout!(pool, :checkout, perform_fun, timeout)
    end

    @impl NimblePool
    def init_pool(pool_state) do
      _ = pool_state[:pool_name] && Process.register(self(), pool_state[:pool_name])
      {:ok, pool_state}
    end

    @impl NimblePool
    def init_worker(pool_state) do
      server_keys = ~w(startup_timeout process_timeout recycle_threshold database_patterns)a
      server_options = pool_state |> Keyword.take(server_keys)
      {:ok, server} = GenMagic.Server.start_link(server_options)
      {:ok, server, pool_state}
    end

    @impl NimblePool
    def handle_checkout(:checkout, _from, server, pool_state) do
      {:ok, server, server, pool_state}
    end

    @impl NimblePool
    def handle_checkin(_, _, server, pool_state) do
      {:ok, server, pool_state}
    end

    @impl NimblePool
    def terminate_worker(_reason, _worker, pool_state) do
      {:ok, pool_state}
    end
  end
end
