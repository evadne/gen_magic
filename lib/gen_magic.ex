defmodule GenMagic do
  @moduledoc """
  Top-level namespace for GenMagic, the libMagic client for Elixir.
  """

  @doc """
  Top-level convenience function which creates an ad-hoc process. Usually
  this will be wrapped in a pool established by the author of the application
  that uses the library.
  """
  def perform(path) do
    {:ok, pid} = __MODULE__.ApprenticeServer.start_link()
    result = GenServer.call(pid, {:perform, path})
    :ok = GenServer.stop(pid)
    result
  end

  def perform_infinite(path) do
    {:ok, pid} = __MODULE__.ApprenticeServer.start_link()
    perform_infinite(path, pid)
  end

  defp perform_infinite(path, pid, count \\ 0) do
    IO.inspect([count, GenServer.call(pid, {:perform, path})])
    perform_infinite(path, pid, count + 1)
  end
end
