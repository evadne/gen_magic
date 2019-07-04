defmodule Infinite do
  @moduledoc """
  Run with a list of files to inspect:

      find /usr/share/ -name *png | xargs mix run test/infinite.exs
  """

  def perform_infinite([]), do: false

  def perform_infinite(paths) do
    {:ok, pid} = GenMagic.ApprenticeServer.start_link()
    perform_infinite(paths, [], pid, 0)
  end

  defp perform_infinite([], done, pid, count) do
    perform_infinite(done, [], pid, count)
  end

  defp perform_infinite([path | paths], done, pid, count) do
    if rem(count, 1000) == 0 do
      IO.puts(Integer.to_string(count))
    end

    {:ok, r} = GenServer.call(pid, {:file, path})
    perform_infinite(paths, [path | done], pid, count + 1)
  end
end

# Run with a list of files to inspect
#
#  find /usr/share/ -name *png | xargs mix run test/infinite.exs

System.argv()
|> Enum.filter(&File.exists?/1)
|> Infinite.perform_infinite()
