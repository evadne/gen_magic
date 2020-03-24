defmodule GenMagic.ApprenticeServer do
  @moduledoc """
  Provides access to the underlying libMagic client which performs file introspection.

  NB If you give a non-existent file, the server will terminate, and you will need to restart another.
  """

  alias GenMagic.Configuration
  use GenServer

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

    worker_timeout = Configuration.get_worker_timeout()

    receive do
      {_, {:data, "ok; " <> message}} ->
        {:reply, parse_response(message), port}

      {_, {:data, "error; " <> message}} ->
        {:reply, {:error, String.trim(message)}, port}

      {_, {:data, _}} ->
        {:stop, :shutdown, {:error, :malformed}, port}
    after
      worker_timeout ->
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

  # def handle_call({:perform, path}, _, state) do
  #   max_count = Configuration.get_recycle_threshold()

  #   case {run(path, state), state.count + 1} do
  #     {{:error, :worker_failure} = reply, _} ->
  #       {:reply, reply, stop(state)}

  #     {reply, ^max_count} ->
  #       {:reply, reply, stop(state)}

  #     {reply, count} ->
  #       {:reply, reply, %{state | count: count}}
  #   end
  # end

  # def handle_info({:DOWN, _, :process, pid, :normal}, state) do
  #   case state.pid do
  #     ^pid -> {:noreply, %State{}}
  #     _ -> {:noreply, state}
  #   end
  # end

  # defp start(%{started: false} = state) do
  #   worker_command = Configuration.get_worker_command()
  #   worker_options = [stdin: true, stdout: true, stderr: true, monitor: true]
  #   worker_timeout = Configuration.get_worker_timeout()
  #   {:ok, pid, ospid} = Exexec.run(worker_command, worker_options)
  #   state = %{state | started: true, pid: pid, ospid: ospid}

  #   receive do
  #     {:stdout, ^ospid, "ok\n"} -> {:ok, state}
  #     {:stdout, ^ospid, "ok\r\n"} -> {:ok, state}
  #   after
  #     worker_timeout ->
  #       {:error, :worker_failure}
  #   end
  # end

  # defp stop(%{started: true} = state) do
  #   :normal = Exexec.stop_and_wait(state.ospid)
  #   %State{}
  # end

  # defp run(path, %{pid: pid, ospid: ospid} = _state) do
  #   worker_timeout = Configuration.get_worker_timeout()
  #   :ok = Exexec.send(pid, "file; " <> path <> "\n")

  #   receive do
  #     {stream, ^ospid, message} ->
  #       handle_response(stream, message)
  #   after
  #     worker_timeout ->
  #       {:error, :worker_failure}
  #   end
  # end

  # TODO handle late responses under load
  # 17:13:47.808 [error] GenServer #PID<0.199.0> terminating
  # ** (FunctionClauseError) no function clause matching in GenMagic.ApprenticeServer.handle_info/2
  #     (gen_magic) lib/gen_magic/apprentice_server.ex:41: GenMagic.ApprenticeServer.handle_info({:stderr, 12304, "\n"}, %GenMagic.ApprenticeServer.State{count: 2, ospid: 12304, pid: #PID<0.243.0>, started: true})
  #     (stdlib) gen_server.erl:637: :gen_server.try_dispatch/4
  #     (stdlib) gen_server.erl:711: :gen_server.handle_msg/6
  #     (stdlib) proc_lib.erl:249: :proc_lib.init_p_do_apply/3
  # Last message: {:stderr, 12304, "\n"}
end
