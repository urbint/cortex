defmodule Cortex.Reloader do
  use GenServer

  @behaviour Cortex.Controller.Stage

  ##########################################
  # Public API
  ##########################################

  @spec start_link :: GenServer.on_start
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end


  @spec reload_file(Path.t) :: :ok | {:error, binary}
  def reload_file(path) do
    GenServer.call(__MODULE__, {:reload_file, path})
  end

  @spec recompile() :: :ok
  def recompile() do
    GenServer.call(__MODULE__, {:recompile})
  end

  ##########################################
  # Controller Stage Callbacks
  ##########################################

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
    {:ok, %{}}
  end


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

  defp reload_or_recompile(path) do
    if File.exists?(path) do
      reload_file(path)
    else
      recompile()
    end
  end
end
