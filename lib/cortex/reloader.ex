defmodule Cortex.Reloader do
  @moduledoc false

  use GenServer

  require Logger

  alias IEx.Helpers, as: IExHelpers

  @behaviour Cortex.Controller.Stage

  ##########################################
  # Public API
  ##########################################

  @spec start_link :: GenServer.on_start
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end


  @spec reload_file(Path.t) :: :ok | {:error, binary}
  def reload_file(path) do
    GenServer.call(__MODULE__, {:reload_file, path}, :infinity)
  end

  @spec recompile :: :ok
  def recompile do
    GenServer.call(__MODULE__, {:recompile}, :infinity)
  end

  ##########################################
  # Controller Stage Callbacks
  ##########################################

  def run_all, do: recompile()

  def file_changed(:lib, path), do: reload_or_recompile(path)

  def file_changed(:test, path) do
    if Path.extname(path) == ".ex" do
      reload_or_recompile(path)
    else
      :ok
    end
  end

  def file_changed(:unknown, _), do: :ok

  def cancel_on_error?, do: true

  ##########################################
  # GenServer Callbacks
  ##########################################

  def init(_) do
    {:ok, %{paths_with_errors: MapSet.new()}}
  end


  def handle_call({:reload_file, path}, _from, state) do
    restore_opts =
      Code.compiler_options()

    Code.compiler_options(ignore_module_conflict: true)

    {result, state} =
      try do
        Code.load_file(path)

        state =
          if MapSet.member?(state.paths_with_errors, path) do
            Logger.warn("Compiler errors resolved for path: #{path}")

            %{state |
              paths_with_errors: MapSet.delete(state.paths_with_errors, path)
            }
          else
            state
          end

        {:ok, state}
      rescue
        ex ->
          state =
            %{state |
              paths_with_errors: MapSet.put(state.paths_with_errors, path)
            }

          error_module =
            ex.__struct__
            |> Module.split() |> Enum.reverse() |> hd()

          error_message =
            case ex do
              %{line: line, file: file, description: desc} ->
                "#{error_module} in #{file}:#{line}:\n\n\t#{desc}\n"

              %{message: message} ->
                "#{error_module}:\n\n\t#{message}\n"
            end

          {{:error, error_message}, state}
      end

    Code.compiler_options(restore_opts)

    {:reply, result, state}
  end

  def handle_call({:recompile}, _from, state) do
    IExHelpers.recompile()
    {:reply, :ok, state}
  end


  ##########################################
  # Private Helpers
  ##########################################

  defp reload_or_recompile(path) do
    if File.exists?(path) do
      reload_file(path)
    else
      recompile()
    end
  end
end
