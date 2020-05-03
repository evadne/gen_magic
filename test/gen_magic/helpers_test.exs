defmodule GenMagic.HelpersTest do
  use GenMagic.MagicCase
  doctest GenMagic.Helpers

  test "perform_once" do
    path = absolute_path("Makefile")
    assert {:ok, %{mime_type: "text/x-makefile"}} = GenMagic.Helpers.perform_once(path)
  end
end
