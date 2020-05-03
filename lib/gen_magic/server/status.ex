defmodule GenMagic.Server.Status do
  @moduledoc """
  Represents Status of the underlying Server.
  """

  @typedoc """
  Represnets Staus of the Server.

  - `:state`: Represents the current state of the Server

  - `:cycles`: Represents the number of cycles the Server has run; note that this resets if
    recycling is enabled.
  """
  @type t :: %__MODULE__{
          state: GenMagic.Server.state(),
          cycles: non_neg_integer()
        }

  defstruct state: nil, cycles: 0
end
