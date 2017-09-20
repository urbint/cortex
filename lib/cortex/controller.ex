defmodule Cortex.Controller do
  @moduledoc false
  use GenServer

  require Logger

  alias Cortex.{Reloader, TestRunner}



  ##########################################
  # Types
  ##########################################

  @type focus :: keyword | nil



  ##########################################
  # Public API
  ##########################################


  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end


  def pipeline(timeout \\ 5000) do
    GenServer.call(__MODULE__, :get_pipeline, timeout)
  end


  def run_all, do: GenServer.cast(__MODULE__, :run_all)


  @doc """
  Update the current focus of Cortex. Arguments are the same tag filters that would be passed to
  ExUnit.

  """
  @spec set_focus(focus) :: :ok
  def set_focus(focus),
    do: GenServer.call(__MODULE__, {:set_focus, focus})


  @doc """
  Clear the Cortex focus.

  """
  @spec clear_focus() :: :ok
  def clear_focus, do: set_focus(nil)



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

    {:ok, %{pipeline: pipeline, focus: []}}
  end


  @impl GenServer
  def handle_cast({:file_changed, type, path}, %{pipeline: pipeline, focus: focus} = state) do
    run_pipeline(pipeline, {:file, type, path}, focus)

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:run_all, %{pipeline: pipeline, focus: focus} = state) do
    run_pipeline(pipeline, :all, focus)

    {:noreply, state}
  end


  @impl GenServer
  def handle_call(:get_pipeline, _from, %{pipeline: pipeline} = state) do
    {:reply, pipeline, state}
  end

  @impl GenServer
  def handle_call({:set_focus, focus}, _from, state) do
    {:reply, :ok, %{state | focus: focus}}
  end



  ##########################################
  # Stage Behaviour
  ##########################################

  defmodule Stage do
    @moduledoc """
    Behaviour for stages that run when files change.

    """

    @typedoc """
    The type of the results to all stage commands
    """
    @type result :: :ok | {:error, any}

    @doc """
    Invoked any time a file is changed by the file watcher.

    The first argument is the type of the file (`:lib`, `:test`, or `:unknown`),
    and the second is the path of the file.

    """
    @callback file_changed(atom, Path.t, Cortex.Controller.focus) :: result

    @doc """
    Run this stage on all possible files
    """
    @callback run_all() :: result

    @doc """
    Returns a boolean for whether or not an error should cancel the rest of the pipeline.

    """
    @callback cancel_on_error?() :: boolean
  end


  ##########################################
  # Private Functions
  ##########################################

  @type command :: {:file, atom, Path.t} | :all

  @spec run_pipeline([module], command, focus) :: :ok | :error
  def run_pipeline([], _command, _focus), do: :ok
  def run_pipeline([stage | rest], command, focus) do
    {results, continue?} =
      call_stage(stage, &run_stage_command(&1, command, focus))

    results
    |> List.wrap
    |> Enum.each(&log_stage/1)

    if continue? do
      run_pipeline(rest, command, focus)
    else
      :error
    end
  end

  @spec run_stage_command(module, command, focus) :: Stage.result
  defp run_stage_command(stage, {:file, type, path}, focus) do
    stage.file_changed(type, path, focus)
  end

  defp run_stage_command(stage, :all, _), do: stage.run_all


  @spec call_stage(stage :: module | [module], fun) :: {:ok | {:error, any}, boolean}
  defp call_stage(stage, cb) when is_atom(stage) do
    result =
      cb.(stage)

    continue? =
      !stage.cancel_on_error? or
      !match?({:error, _}, result)

    {result, continue?}
  end

  defp call_stage(stages, cb) when is_list(stages) do
    stages
    |> Enum.map(&call_stage(&1, cb))
    |> Task.yield_many
    |> Stream.map(&handle_task_result/1)
    |> Enum.unzip
    |> Enum.map(fn {result, continue} -> {result, Enum.all?(continue)} end)
  end

  defp handle_task_result({:ok, result}), do: result
  defp handle_task_result({:exit, reason}) do
    Logger.error "[Cortex] Pipeline stage exited unexpectedly \
(reason: #{inspect reason}). Dying."
    raise RuntimeError, "Unexpected crash of pipeline stage process"
  end

  defp handle_task_result(nil) do
    Logger.error "[Cortex] Timed out waiting for pipeline stage. Dying \
horribly in a fire"
    raise RuntimeError, "Timed out waiting for pipeline stage"
  end

  defp log_stage(:ok), do: :ok
  defp log_stage({:error, reason}) do
    Logger.warn "[Cortex] Received error from pipeline stage!"
    Logger.warn reason
  end
end
