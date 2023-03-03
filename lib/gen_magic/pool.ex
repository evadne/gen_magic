defmodule GenMagic.Pool do
  @moduledoc """
  The `GenMagic.Pool` behaviour defines functions that must be implemented by each pool module
  which is added under the `GenMagic.Pool` namespace.
  """

  alias GenMagic.Result

  @typedoc "The name of the pool, which is usually a pid or an atom for named pools"
  @type name :: term()

  @typedoc "The options that must be accepted by the pool"
  @type startup_option ::
          {:pool_name, atom()}
          | {:pool_size, non_neg_integer()}
          | {:startup_timeout, timeout()}
          | {:process_timeout, timeout()}
          | {:recycle_threshold, non_neg_integer() | :infinity}
          | {:database_patterns, nonempty_list(:default | Path.t())}

  @type perform_option ::
          {:timeout, timeout()}

  @callback start_link([startup_option]) :: {:ok, pid()} | {:error, term()}
  @callback perform(name(), Path.t(), [perform_option]) :: {:ok, Result.t()} | {:error, term()}
end
