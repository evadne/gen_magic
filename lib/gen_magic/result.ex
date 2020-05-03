defmodule GenMagic.Result do
  @moduledoc """
  Represents the results obtained from libmagic.

  Please note that this struct is only returned if the underlying check has succeeded.
  """

  @typedoc """
  Represents the result.

  Contains the MIME type, Encoding and Content fields returned by libmagic, as per the flags:

  - MIME Type: `MAGIC_FLAGS_COMMON|MAGIC_MIME_TYPE`
  - Encoding: `MAGIC_FLAGS_COMMON|MAGIC_MIME_ENCODING`
  - Type Name (Content): `MAGIC_FLAGS_COMMON|MAGIC_NONE`
  """
  @type t :: %__MODULE__{
          mime_type: String.t(),
          encoding: String.t(),
          content: String.t()
        }

  @enforce_keys ~w(mime_type encoding content)a
  defstruct mime_type: nil, encoding: nil, content: nil

  @doc false
  def build(mime_type, encoding, content) do
    %__MODULE__{mime_type: mime_type, encoding: encoding, content: content}
  end
end
