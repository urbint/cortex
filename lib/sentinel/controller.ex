defmodule Sentinel.Controller do
  @moduledoc false
  use GenServer

  require Logger

  alias Sentinel.{Reloader,TestRunner}


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
    pipeline =
      case Mix.env do
        :dev -> [Reloader]
        :test -> [Reloader, TestRunner]
      end

    {:ok, %{pipeline: pipeline}}
  end

  def handle_cast({:file_changed, type, path}, %{pipeline: pipeline} = state) do
    for stage <- pipeline do

      case stage do
        single when is_atom(single) ->
          single.file_changed(type, path)

        many when is_list(many) ->
          tasks =
            many
            |> Enum.map(fn -> Task.async(&(&1.file_changed(type, path))) end)

          Task.yield_many(tasks)
          |> Enum.map(fn
            {:ok, result} ->
              result

            {:exit, reason} ->
              Logger.error "[Sentinel] Pipeline stage exited unexpectedly (reason: #{inspect reason}). Dying."
            raise RuntimeError, "Unexpected crash of pipeline stage process"

            nil ->
              Logger.error "[Sentinel] Timed out waiting for pipeline stage. Dying horribly in a fire"
            raise RuntimeError, "Timed out waiting for pipeline stage"
          end)
      end
      |> List.wrap()
      |> Enum.each(&log_stage/1)
    end

    {:noreply, state}
  end

  defp log_stage(:ok), do: :ok
  defp log_stage({:error, reason}) do
    Logger.warn "Received error from pipeline stage: #{inspect reason}"
  end

  defmodule Stage do
    @doc """
    Invoked any time a file is changed by the file watcher.

    The first argument is the type of the file (`:lib`, `:test`, or `:unknown`),
    and the second is the path of the file.

    """
    @callback file_changed(atom, Path.t) :: :ok | {:error, any}
  end
end
