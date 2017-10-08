defmodule Cortex.FileWatcher do
  @moduledoc false

  alias Cortex.Controller

  require Logger

  use GenServer

  @watched_dirs ["lib/", "test/", "apps/"]
  @debounce_timeout 100

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
    {:ok, watcher_pid} =
      FileSystem.start_link(dirs: watched_dirs())

    FileSystem.subscribe(watcher_pid)

    {:ok, %{watcher_pid: watcher_pid, debounce_timers: %{}}}
  end

  def handle_info({:file_event, watcher_pid, {path, _events}},
                  %{watcher_pid: watcher_pid, debounce_timers: debounce_timers} = state) do
    with {:ok, old_timer} <- Map.fetch(debounce_timers, path) do
      Process.cancel_timer(old_timer)
    end

    timer =
      Process.send_after(self(), {:debounce_timer_complete, path}, @debounce_timeout)

    {:noreply, put_in(state[:debounce_timers][path], timer)}
  end

  def handle_info({:debounce_timer_complete, path}, %{debounce_timers: debounce_timers} = state) do
    GenServer.cast(Controller, {:file_changed, file_type(path), path})

    {:noreply, %{state | debounce_timers: Map.delete(debounce_timers, path)}}
  end

  def handle_info({:file_event, watcher_pid, :stop}, %{watcher_pid: watcher_pid} = state) do
    Logger.info "File watcher stopped."

    {:noreply, state}
  end

  def handle_info(data, state) do
    Logger.info "Get unexcepted message #{inspect data}, ignore..."

    {:noreply, state}
  end


  ##########################################
  # Private Helpers
  ##########################################

  # public only because it is tested
  @spec file_type(Path.t) :: :lib | :test | :unknown
  def file_type(path) do
    is_elixir_file? =
      Regex.match?(~r/\/(\w|_)+\.exs?/, path)

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
  @spec watched_dirs() :: [Path.t]
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
