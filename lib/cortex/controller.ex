defmodule Cortex.Controller do
  @moduledoc false
  use GenServer

  require Logger

  alias Cortex.{Reloader,TestRunner}


  ##########################################
  # Public API
  ##########################################

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  ##########################################
  # GenServer Callbacks
  ##########################################

  def init(_) do
    dirs = ["lib/", "test/", "apps/"] |> Enum.filter(&File.dir?/1)
    {:ok, watcher_pid} = FileSystem.start_link(dirs: dirs)
    FileSystem.subscribe(watcher_pid)

    pipeline =
      case Mix.env do
        :dev -> [Reloader]
        :test -> [Reloader, TestRunner]
      end

    {:ok, %{watcher_pid: watcher_pid, pipeline: pipeline}}
  end

  def handle_info({:file_event, watcher_pid, {path, _events}}, %{watcher_pid: watcher_pid}=state) do
    run_pipeline(state.pipeline, file_type(path), path)
    {:noreply, state}
  end

  def handle_info({:file_event, watcher_pid, :stop}, %{watcher_pid: watcher_pid}=state) do
    Logger.info "File watcher stopped."
    {:noreply, state}
  end

  def handle_info(data, state) do
    Logger.info "Get unexcepted message #{inspect data}, ignore..."
    {:noreply, state}
  end


  def file_type(path) do
    is_elixir_file? =
      Regex.match?(~r/\/(\w|_)+\.exs?/, path)

    cond do
      is_elixir_file? and Regex.match?(~r/lib\//, path) ->
        :lib

      is_elixir_file? and Regex.match?(~r/test\//, path) ->
        :test

      true ->
        :unknown
    end
  end

  ##########################################
  # Stage Module
  ##########################################

  defmodule Stage do
    @doc """
    Invoked any time a file is changed by the file watcher.

    The first argument is the type of the file (`:lib`, `:test`, or `:unknown`),
    and the second is the path of the file.

    """
    @callback file_changed(atom, Path.t) :: :ok | {:error, any}


    @doc """
    Returns a boolean for whether or not an error should cancel the rest of the pipeline.

    """
    @callback cancel_on_error? :: boolean
  end


  ##########################################
  # Private Functions
  ##########################################

  defmacrop result_and_continue?(stage, result) do
    quote do
      if unquote(stage).cancel_on_error?() and match?({:error, _}, unquote(result)) do
        {unquote(result), false}
      else
        {unquote(result), true}
      end
    end
  end

  def run_pipeline([], _type, _path), do: :ok
  def run_pipeline([stage | rest], type, path) do
    {results, continue?} =
      case stage do
        single when is_atom(single) ->
          result =
            single.file_changed(type, path)

          result_and_continue?(single, result)

        many when is_list(many) ->
          tasks =
            many
            |> Enum.map(fn -> Task.async(&({&1, &1.file_changed(type, path)})) end)

          Task.yield_many(tasks)
          |> Stream.map(fn
            {:ok, {stage, result}} ->
              result_and_continue?(stage, result)

            {:exit, reason} ->
              Logger.error "[Cortex] Pipeline stage exited unexpectedly (reason: #{inspect reason}). Dying."
              raise RuntimeError, "Unexpected crash of pipeline stage process"

            nil ->
              Logger.error "[Cortex] Timed out waiting for pipeline stage. Dying horribly in a fire"
              raise RuntimeError, "Timed out waiting for pipeline stage"
          end)
          |> Enum.unzip()
          |> Enum.map(&({elem(&1, 0), elem(&1, 1) |> Enum.all?()}))
      end

    results
    |> List.wrap()
    |> Enum.each(&log_stage/1)

    if continue? do
      run_pipeline(rest, type, path)
    end
  end

  defp log_stage(:ok), do: :ok
  defp log_stage({:error, reason}) do
    Logger.warn "[Cortex] Received error from pipeline stage!"
    Logger.warn reason
  end

end
