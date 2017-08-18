defmodule Cortex.Reloader do
  @moduledoc """
  `Cortex.Controller.Stage` module responsible for recompiling / reloading changed files.

  See the `Cortex.Controller.Stage`module for more information about Cortex's stages.

  """

  alias Cortex.Controller.Stage

  use GenServer

  @behaviour Stage



  ##########################################
  # Public API
  ##########################################

  @spec start_link :: GenServer.on_start
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end


  @doc """
  Wraps `Code.load_file/*` to provide error-handling for the following error types:
  `SyntaxError`, `CompileError`, and `ArgumentError`.

  """
  @spec reload_file(Path.t) :: :ok | {:error, binary}
  def reload_file(path) do
    GenServer.call(__MODULE__, {:reload_file, path}, :infinity)
  end


  @doc """
  Recompiles the Mix application.

  """
  @spec recompile() :: :ok
  def recompile() do
    GenServer.call(__MODULE__, {:recompile}, :infinity)
  end



  ##########################################
  # Controller Stage Callbacks
  ##########################################

  @impl Stage
  def file_changed(:lib, path),
    do: reload_or_recompile(path)

  def file_changed(:test, path) do
    case Path.extname(path)do
      ".ex" -> reload_or_recompile(path)
      _     -> :ok # no-op
    end
  end

  def file_changed(:unknown, _path),
    do: :ok


  @impl Stage
  def cancel_on_error?, do: true


  ##########################################
  # GenServer Callbacks
  ##########################################

  @impl GenServer
  def init(_) do
    {:ok, %{}}
  end


  @impl GenServer
  def handle_call({:reload_file, path}, _from, state) do
    restore_opts =
      Code.compiler_options()

    Code.compiler_options(ignore_module_conflict: true)

    result =
      try do
        Code.load_file(path)
        :ok
      rescue
        ex in [SyntaxError, CompileError, ArgumentError] ->
          %{__struct__: struct, line: line, file: file, description: desc} =
            ex

          error_type =
            Module.split(struct) |> Enum.reverse() |> hd()

          desc =
            "#{error_type} in #{file}:#{line}:\n\n\t#{desc}\n"

          {:error, desc}
      end

    Code.compiler_options(restore_opts)

    {:reply, result, state}
  end

  def handle_call({:recompile}, _from, state) do
    IEx.Helpers.recompile()
    {:reply, :ok, state}
  end


  ##########################################
  # Private Helpers
  ##########################################

  @spec reload_or_recompile(Path.t) :: :ok | {:error, binary}
  defp reload_or_recompile(path) do
    if File.exists?(path) do
      reload_file(path)
    else
      recompile()
    end
  end

end
