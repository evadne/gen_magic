defmodule GenMagicTest do
  use ExUnit.Case
  doctest GenMagic

  test "greets the world" do
    assert GenMagic.hello() == :world
  end
end
