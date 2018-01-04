defmodule Cortex.CredoRunner do
  @moduledoc false
  use GenServer


  @behaviour Cortex.Controller.Stage



  ##########################################
  # Public API
  ##########################################

  @spec start_link :: GenServer.on_start
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end


  @spec run_credo_for_file(Path.t, keyword) :: :ok | {:error, String.t}
  def run_credo_for_file(path, opts \\ []) do
    GenServer.call(__MODULE__, {:run_for_file, path, opts}, :infinity)
  end



  ##########################################
  # Controller Stage Callbacks
  ##########################################

  @spec run_all :: :ok | {:error, String.t}
  def run_all do
    GenServer.call(__MODULE__, :run_all, :infinity)
  end

  def file_changed(_relevant, path) do
    run_credo_for_file(path)
  end

  def cancel_on_error?, do: false



  ##########################################
  # GenServer Callbacks
  ##########################################

  def init(_) do
    Application.ensure_started(:ex_unit)
    {:ok, %{}}
  end


  def handle_call({:run_for_file, path, _opts}, _from, state) do
    Credo.CLI.main(["--strict", "--mute-exit-status", path])

    {:reply, :ok, state}
  end

  def handle_call(:run_all, _from, state) do
    Credo.CLI.main(["--strict", "--mute-exit-status"])

    {:reply, :ok, state}
  end

end
