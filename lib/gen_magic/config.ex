defmodule GenMagic.Config do
  @moduledoc false
  @otp_app Mix.Project.config()[:app]
  @executable_name "apprentice"
  @startup_timeout 1_000
  @process_timeout 30_000
  @recycle_threshold :infinity
  @database_patterns [:default]

  def get_port_name do
    {:spawn_executable, to_charlist(get_executable_name())}
  end

  def get_port_options(options) do
    arguments = [:use_stdio, :binary, :exit_status, {:packet, 2}]

    case get_executable_arguments(options) do
      [] -> arguments
      list -> [{:args, list} | arguments]
    end
  end

  def get_startup_timeout(options) do
    get_value(options, :startup_timeout, @startup_timeout)
  end

  def get_process_timeout(options) do
    get_value(options, :process_timeout, @process_timeout)
  end

  def get_recycle_threshold(options) do
    get_value(options, :recycle_threshold, @recycle_threshold)
  end

  defp get_executable_name do
    Path.join(:code.priv_dir(@otp_app), @executable_name)
  end

  defp get_executable_arguments(options) do
    Enum.flat_map(List.wrap(get(options, :database_patterns, @database_patterns)), fn
      :default -> ["--database-default"]
      pattern -> pattern |> Path.wildcard() |> Enum.flat_map(&["--database-file", &1])
    end)
  end

  defp get(options, key, default) do
    Keyword.get(options, key, default)
  end

  defp get_value(options, key, default) do
    case get(options, key, default) do
      value when is_integer(value) and value > 0 -> value
      :infinity -> :infinity
      _ -> raise ArgumentError, message: "Invalid #{key}"
    end
  end
end
