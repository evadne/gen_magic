defmodule GenMagic.Pool do
  @behaviour NimblePool
  @moduledoc "Pool of `GenMagic.Server`"

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(options, pool_size \\ nil) do
    pool_size = pool_size || System.schedulers_online()
    NimblePool.start_link(worker: {__MODULE__, options}, pool_size: pool_size)
  end

  def perform(pool, path, opts \\ []) do
    pool_timeout = Keyword.get(opts, :pool_timeout, 5000)
    timeout = Keyword.get(opts, :timeout, 5000)

    NimblePool.checkout!(
      pool,
      :checkout,
      fn _, server ->
        {GenMagic.Server.perform(server, path, timeout), server}
      end,
      pool_timeout
    )
  end

  @impl NimblePool
  def init_pool(options) do
    {name, options} =
      case Keyword.pop(options, :name) do
        {name, options} when is_atom(name) -> {name, options}
        {nil, options} -> {__MODULE__, options}
        {_, options} -> {nil, options}
      end

    if name, do: Process.register(self(), name)
    {:ok, options}
  end

  @impl NimblePool
  def init_worker(options) do
    {:ok, server} = GenMagic.Server.start_link(options || [])
    {:ok, server, options}
  end

  @impl NimblePool
  def handle_checkout(:checkout, _from, server) do
    {:ok, server, server}
  end

  @impl NimblePool
  def handle_checkin(_, _, server) do
    {:ok, server}
  end

  @impl NimblePool
  def terminate_worker(_reason, _worker, state) do
    {:ok, state}
  end
end
