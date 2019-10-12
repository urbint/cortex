defmodule Cortex.FileWatcherTest do
  use ExUnit.Case

  alias Cortex.FileWatcher

  @throttle_timeout_ms 10

  test "file_type" do
    assert FileWatcher.file_type("test/some_file.exs") == :test
    assert FileWatcher.file_type("lib/some_file.ex") == :lib
    assert FileWatcher.file_type("lib/.#some_file.ex") == :unknown
  end

  test "with one file event received, file changed is sent once" do
    {watcher, watcher_pid} = start_file_watcher()

    path = "test/some_file.exs"

    send_file_event(watcher, watcher_pid, path, [:created, :modified])

    assert_receive {:"$gen_cast", {:file_changed, :test, path}}
    refute_receive {:"$gen_cast", {:file_changed, :lib, _}}
  end

  test "with one path event multiple times, file changed is sent once" do
    {watcher, watcher_pid} = start_file_watcher()

    path = "lib/some_file.ex"

    send_file_event(watcher, watcher_pid, path, [:inodemetamod, :modified])
    send_file_event(watcher, watcher_pid, path, [:inodemetamod, :modified])
    send_file_event(watcher, watcher_pid, path, [:inodemetamod, :modified])

    assert_receive {:"$gen_cast", {:file_changed, :lib, path}}
    refute_receive {:"$gen_cast", {:file_changed, :lib, _}}
  end

  test "with multiple paths events sent multiple times, file changed is sent once per path" do
    {watcher, watcher_pid} = start_file_watcher()

    path1 = "lib/some_file.ex"
    path2 = "lib/another_file.ex"

    send_file_event(watcher, watcher_pid, path1, [:inodemetamod, :modified])
    send_file_event(watcher, watcher_pid, path1, [:inodemetamod, :modified])
    Process.sleep(3)
    send_file_event(watcher, watcher_pid, path2, [:created, :modified])
    send_file_event(watcher, watcher_pid, path1, [:inodemetamod, :modified])

    assert_receive {:"$gen_cast", {:file_changed, :lib, path1}}
    assert_receive {:"$gen_cast", {:file_changed, :lib, path2}}
    refute_receive {:"$gen_cast", {:file_changed, :lib, _}}
  end

  defp start_file_watcher do
    watcher =
      start_supervised!(
        {FileWatcher, file_changed_receiver: self(), throttle_timeout_ms: @throttle_timeout_ms}
      )

    %FileWatcher.State{watcher_pid: watcher_pid} = :sys.get_state(watcher)
    {watcher, watcher_pid}
  end

  defp send_file_event(watcher, watcher_pid, path, events) do
    message = {:file_event, watcher_pid, {path, events}}
    send(watcher, message)
  end
end
