defmodule GenMagic.Helpers do
  @moduledoc """
  Contains convenience functions for one-off use.
  """

  alias GenMagic.Result
  alias GenMagic.Server

  @spec perform_once(Path.t() | {:bytes, binary}, [Server.option()]) ::
          {:ok, Result.t()} | {:error, term()}

  @doc """
  Runs a one-shot process without supervision.

  Useful in tests, but not recommended for actual applications.

  ## Example

      iex(1)> {:ok, result} = GenMagic.Helpers.perform_once(".")
      iex(2)> result
      %GenMagic.Result{content: "directory", encoding: "binary", mime_type: "inode/directory"}
  """
  def perform_once(path, options \\ []) do
    with {:ok, pid} <- Server.start_link(options),
         {:ok, result} <- Server.perform(pid, path),
         :ok <- Server.stop(pid) do
      {:ok, result}
    end
  end
end
