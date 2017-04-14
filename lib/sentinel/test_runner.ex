defmodule Sentinel.TestRunner do
  @moduledoc false
  use GenServer

  @behaviour Sentinel.Controller.Stage

  ##########################################
  # Public API
  ##########################################

  @spec start_link :: GenServer.on_start
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end


  @spec run_tests_for_file(Path.t, keyword) :: :ok | {:error, String.t}
  def run_tests_for_file(path, opts \\ []) do
    GenServer.call(__MODULE__, {:run_tests_for_file, path, opts})
  end

  ##########################################
  # Controller Stage Callbacks
  ##########################################
  
  def file_changed(relevant, path) when relevant in [:lib, :test] do
    run_tests_for_file(path)
  end
  def file_changed(_, _), do: :ok



  ##########################################
  # GenServer Callbacks
  ##########################################
  
  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:run_tests_for_file, path, _opts}, _from, state) do
    IO.puts "Running tests for file #{path}"
    {:reply, :ok, state}
  end
end
