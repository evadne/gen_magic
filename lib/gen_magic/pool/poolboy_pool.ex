if Code.ensure_loaded?(:poolboy) do
  defmodule GenMagic.Pool.Poolboy do
    @moduledoc "Generic module providing pooling of `GenMagic.Server` by using Poolboy"
    @behaviour GenMagic.Pool

    use Supervisor

    defmodule Worker do
      @moduledoc false
      @behaviour :poolboy_worker
      @impl :poolboy_worker
      def start_link(options) do
        GenMagic.Server.start_link(options)
      end
    end

    @impl GenMagic.Pool
    def start_link(options) do
      options[:pool_name] || raise ArgumentError, "pool_name must be set"
      Supervisor.start_link(__MODULE__, options)
    end

    @impl Supervisor
    def init(options) do
      {pool_name, options} = Keyword.pop!(options, :pool_name)
      {pool_size, options} = Keyword.pop(options, :pool_size, System.schedulers_online())
      pool_config = [worker_module: Worker, size: pool_size]

      pool_config =
        (pool_name && put_in(pool_config, [:name], {:local, pool_name})) || pool_config

      children = [:poolboy.child_spec(__MODULE__, pool_config, options)]
      Supervisor.init(children, strategy: :one_for_one, max_restarts: 60, max_seconds: 60)
    end

    @impl GenMagic.Pool
    def perform(pool, path, options) do
      timeout = Keyword.get(options, :timeout, 5000)

      :poolboy.transaction(pool, fn server_ref ->
        GenMagic.Server.perform(server_ref, path, timeout)
      end)
    end
  end
end
