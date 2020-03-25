defmodule GenMagic.Configuration do
  @moduledoc """
  Convenience module which returns information from configuration.
  """

  @otp_app Mix.Project.config()[:app]

  def get_worker_command(patterns) do
    database_paths = paths(patterns)
    worker_path = Path.join(:code.priv_dir(@otp_app), get_worker_name())
    worker_arguments = Enum.flat_map(database_paths, &["--file", &1])
    {worker_path, worker_arguments}
  end

  def get_worker_name do
    get_env(:worker_name)
  end

  def get_worker_timeout do
    get_env(:worker_timeout)
  end

  def get_recycle_threshold do
    get_env(:recycle_threshold)
  end

  def get_database_patterns do
    case get_env(:database_patterns) do
      nil -> []
      l when is_list(l) -> l
      s when is_binary(s) -> [s]
    end
  end

  defp get_env(key) do
    Application.get_env(@otp_app, key)
  end

  defp paths(patterns),
    do: patterns |> Enum.flat_map(&Path.wildcard/1) |> Enum.filter(&File.exists?/1)
end
