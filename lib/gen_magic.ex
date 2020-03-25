defmodule GenMagic do
  @moduledoc """
  Top-level namespace for GenMagic, the libMagic client for Elixir.
  """

  alias GenMagic.ApprenticeServer

  @doc """
  Top-level convenience function which creates an ad-hoc process. Usually
  this will be wrapped in a pool established by the author of the application
  that uses the library.
  """
  def perform(path) do
    {:ok, pid} = ApprenticeServer.start_link([])
    result = ApprenticeServer.file(pid, path)
    :ok = GenServer.stop(pid)
    result
  end
end
