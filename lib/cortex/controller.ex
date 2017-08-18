defmodule Cortex.Controller do
  @moduledoc """
  Module responsible for receiving events from the `FileWatcher` and executing the appropriate
  pipeline.

  """

  require Logger

  alias Cortex.{FileWatcher, Reloader, TestRunner}

  use GenServer



  ##########################################
  # Public API
  ##########################################

  @spec start_link :: GenServer.on_start
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end



  ##########################################
  # GenServer Callbacks
  ##########################################

  @impl GenServer
  def init(_) do
    pipeline =
      case Mix.env do
        :dev  -> [Reloader]
        :test -> [Reloader, TestRunner]
      end

    {:ok, %{pipeline: pipeline}}
  end


  @impl GenServer
  def handle_cast({:file_changed, type, path}, %{pipeline: pipeline} = state) do
    run_pipeline(pipeline, type, path)

    {:noreply, state}
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


  @spec run_pipeline(stages :: [module], FileWatcher.file_type, Path.t) :: :ok
  defp run_pipeline([], _type, _path),
    do: :ok

  defp run_pipeline([stage | rest], type, path) do
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


  @spec log_stage(stage_result) :: :ok | {:error, reason}
        when stage_result: :ok | {:error, reason},
             reason: any
  defp log_stage(:ok),
    do: :ok

  defp log_stage({:error, reason}) do
    Logger.warn "[Cortex] Received error from pipeline stage!"
    Logger.warn reason
  end

end
