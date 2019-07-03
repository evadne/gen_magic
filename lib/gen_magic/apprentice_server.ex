defmodule GenMagic.ApprenticeServer do
  @moduledoc """
  Provides access to the underlying libMagic client which performs file introspection.
  """

  alias GenMagic.Configuration
  use GenServer

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args)
  end

  defmodule State do
    defstruct pid: nil, ospid: nil, started: false, count: 0
  end

  def init(_) do
    {worker_path, worker_arguments} = Configuration.get_worker_command()
    # worker_options = [stdin: true, stdout: true, stderr: true, monitor: true]
    # worker_timeout = Configuration.get_worker_timeout()
    case File.stat(worker_path) do
      {:ok, _} ->
        port =
          Port.open({:spawn_executable, worker_path}, [
            :stderr_to_stdout,
            :binary,
            :exit_status,
            args: worker_arguments
          ])

        receive do
          {_, {:data, "ok\n"}} ->
            {:ok, port}
        after
          1_000 ->
            {:stop, :shutdown}
        end

      {:error, _} = e ->
        {:stop, e}
    end
  end

  def handle_call({:file, path}, _from, port) do
    cmd = "file; " <> path <> "\n"
    send(port, {self(), {:command, cmd}})

    worker_timeout = Configuration.get_worker_timeout()

    receive do
      {_, {:data, message}} ->
        case handle_response(:stdin, message) do
          {:ok, response} -> {:reply, response, port}
          other -> {:reply, other, port}
        end
    after
      worker_timeout ->
        {:error, :worker_failure}
    end
  end

  # def handle_call(message, from, %{started: false} = state) do
  #   case start(state) do
  #     {:ok, state} -> handle_call(message, from, state)
  #     {:error, _} = error -> {:reply, error, state}
  #   end
  # end

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

  def terminate(_reason, port) do
    case send(port, {self(), :close}) do
      {_, :close} -> :ok
      _ -> :ok
    end
  end

  def handle_info({_, {:exit_status, 1}}, port) do
    {:stop, :shutdown, port}
  end

  def handle_info({_, {:data, "ok\n"}}, port) do
    {:noreply, port}
  end

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

  defp handle_response(:stdin, "ok; " <> message) do
    case message |> String.trim() |> String.split("\t") do
      [mime_type, encoding, content] ->
        {:ok, {:ok, [mime_type: mime_type, encoding: encoding, content: content]}}

      _ ->
        {:error, :malformed_response}
    end
  end

  # defp handle_response(:stderr, "error; " <> message) do
  #   {:error, String.trim(message)}
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
