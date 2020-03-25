defmodule GenMagic.ApprenticeServer do
  @moduledoc """
  Provides access to the underlying libMagic client which performs file introspection.

  This server needs to be supervised, as if it receives any unexpected error, it will terminate.
  """

  alias GenMagic.Configuration
  use GenServer

  @type result() :: [mime_type: String.t(), encoding: String.t(), content: String.t()]

  @worker_timeout Configuration.get_worker_timeout()

  def start_link([]) do
    database_patterns = Configuration.get_database_patterns()
    GenServer.start_link(__MODULE__, database_patterns: database_patterns)
  end

  def start_link(name: name) do
    database_patterns = Configuration.get_database_patterns()
    GenServer.start_link(__MODULE__, [database_patterns: database_patterns], name: name)
  end

  def start_link([database_patterns: _] = args) do
    GenServer.start_link(__MODULE__, args)
  end

  def start_link(database_patterns: database_patterns, name: name) do
    GenServer.start_link(__MODULE__, [database_patterns: database_patterns], name: name)
  end

  @doc """
  Determine a file type.
  """
  @spec file(pid() | atom(), String.t()) :: {:ok, result()} | {:error, term()}
  def file(pid, path) do
    GenServer.call(pid, {:file, path})
  end

  def init(database_patterns: database_patterns) do
    {worker_path, worker_arguments} = Configuration.get_worker_command(database_patterns)

    case File.stat(worker_path) do
      {:ok, _} ->
        port =
          Port.open({:spawn_executable, to_charlist(worker_path)}, [
            :stderr_to_stdout,
            :binary,
            :exit_status,
            args: worker_arguments
          ])

        {:ok, port, {:continue, :verify_port}}

      {:error, _} = e ->
        {:stop, e}
    end
  end

  # The process sends us an ack when it has read the databases
  # and is ready to receive data.
  # OTP-13019 Requires OTP 21
  def handle_continue(:verify_port, port) do
    receive do
      {_, {:data, "ok\n"}} ->
        {:noreply, port}
    after
      10_000 ->
        {:stop, :nok, port}
    end
  end

  def handle_call({:file, path}, _from, port) do
    cmd = "file; " <> path <> "\n"
    send(port, {self(), {:command, cmd}})

    receive do
      {_, {:data, "ok; " <> message}} ->
        {:reply, parse_response(message), port}

      {_, {:data, "error; " <> message}} ->
        {:reply, {:error, String.trim(message)}, port}

      {_, {:data, _}} ->
        {:stop, :shutdown, {:error, :malformed}, port}
    after
      @worker_timeout ->
        {:stop, :shutdown, {:error, :worker_failure}, port}
    end
  end

  defp parse_response(message) do
    case message |> String.trim() |> String.split("\t") do
      [mime_type, encoding, content] ->
        {:ok, [mime_type: mime_type, encoding: encoding, content: content]}

      _ ->
        {:error, :malformed_response}
    end
  end

  def terminate(_reason, port) do
    case send(port, {self(), :close}) do
      {_, :close} -> :ok
      _ -> :ok
    end
  end

  def handle_info({_, {:exit_status, 1}}, port) do
    {:stop, :shutdown, port}
  end

  # Server is overloaded - late replies
  # Normally caused only when previous call errors
  def handle_info({_, {:data, _}}, port) do
    {:stop, :shutdown, port}
  end
end
