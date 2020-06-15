defmodule GenMagic.Server.Data do
  @moduledoc false

  @type request :: {Path.t(), {pid(), term()}, requested_at :: integer()}

  @type t :: %__MODULE__{
          port_name: Port.name(),
          port_options: list(),
          port: port(),
          startup_timeout: timeout(),
          process_timeout: timeout(),
          recycle_threshold: non_neg_integer() | :infinity,
          cycles: non_neg_integer(),
          request: request | nil
        }

  defstruct port_name: nil,
            port_options: nil,
            port: nil,
            startup_timeout: :infinity,
            process_timeout: :infinity,
            recycle_threshold: :infinity,
            cycles: 0,
            database_patterns: nil,
            request: nil
end
