defmodule Cortex.FileWatcher do
  @moduledoc false

  alias Cortex.Controller

  require Logger

  use GenServer

  @watched_dirs ["lib/", "test/", "apps/"]
  @throttle_timeout_ms 100

  defmodule State do
    defstruct [:watcher_pid, :file_events, :throttle_timer]
  end

  ##########################################
  # Public API
  ##########################################

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  ##########################################
  # GenServer Callbacks
  ##########################################

  def init(_) do
    {:ok, watcher_pid} = FileSystem.start_link(dirs: watched_dirs())

    FileSystem.subscribe(watcher_pid)

    {:ok, %State{watcher_pid: watcher_pid, throttle_timer: nil, file_events: %{}}}
  end

  def handle_info(
        {:file_event, watcher_pid, {path, _events}},
        %{watcher_pid: watcher_pid} = state
      ) do
    state =
      state
      |> maybe_update_throttle_timer()
      |> track_file_events(path)

    {:noreply, state}
  end

  def handle_info({:file_event, watcher_pid, :stop}, %{watcher_pid: watcher_pid} = state) do
    Logger.info("File watcher stopped.")

    {:noreply, state}
  end

  def handle_info(:throttle_timer_complete, state) do
    %State{file_events: file_events} = state

    Enum.each(file_events, fn {path, file_type} ->
      GenServer.cast(Controller, {:file_changed, file_type, path})
    end)

    {:noreply, %State{state | file_events: %{}, throttle_timer: nil}}
  end

  def handle_info(data, state) do
    Logger.info("Get unexcepted message #{inspect(data)}, ignore...")

    {:noreply, state}
  end

  ##########################################
  # Private Helpers
  ##########################################

  defp maybe_update_throttle_timer(%State{throttle_timer: nil} = state) do
    throttle_timer = Process.send_after(self(), :throttle_timer_complete, @throttle_timeout_ms)
    %State{state | throttle_timer: throttle_timer}
  end

  defp maybe_update_throttle_timer(state), do: state

  defp track_file_events(%State{file_events: file_events} = state, path) do
    file_events = Map.put(file_events, path, file_type(path))
    %State{state | file_events: file_events}
  end

  # public only because it is tested
  @spec file_type(Path.t()) :: :lib | :test | :unknown
  def file_type(path) do
    is_elixir_file? = Regex.match?(~r/\/(\w|_)+\.exs?/, path)

    cond do
      is_elixir_file? and Regex.match?(~r/lib\//, path) ->
        :lib

      is_elixir_file? and Regex.match?(~r/test\//, path) ->
        :test

      true ->
        :unknown
    end
  end

  # Returns a list of all directories to monitor for file changes.
  # Includes dependencies.
  @spec watched_dirs() :: [Path.t()]
  defp watched_dirs do
    Mix.Project.deps_paths()
    |> Stream.flat_map(fn {_dep_name, dir} ->
      @watched_dirs
      |> Enum.map(fn watched_dir ->
        Path.join(dir, watched_dir)
      end)
    end)
    |> Stream.concat(@watched_dirs)
    |> Enum.filter(&File.dir?/1)
  end
end
