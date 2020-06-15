defmodule GenMagic.MagicCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      import unquote(__MODULE__)
    end
  end

  def missing_filename do
    :crypto.strong_rand_bytes(8) |> Base.url_encode64()
  end

  def files_stream do
    Path.join(File.cwd!(), "deps/**/*")
    |> Path.wildcard()
    |> Stream.reject(&File.dir?/1)
    |> Stream.chunk_every(10)
    |> Stream.flat_map(&Enum.shuffle/1)
  end

  def assert_no_file(message) do
    assert {:error, :enoent} = message
  end

  def absolute_path(path) do
    __ENV__.file
    |> Path.join("../../..")
    |> Path.join(path)
    |> Path.expand()
  end
end
