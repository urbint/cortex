defmodule Sentinel.FileWatcher do
  @moduledoc false
  use GenServer

  alias __MODULE__.Worker

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
    Worker.start
    {:ok, %{}}
  end

  def handle_cast({:file_changed, type, path}, state) do
    IO.puts "File changed: #{type} #{path}"

    {:noreply, state}
  end
end
