defmodule Sentinel.FileWatcherTest do
  use ExUnit.Case

  alias Sentinel.FileWatcher

  test "file_type" do
    assert FileWatcher.file_type("test/some_file.exs") == :test
    assert FileWatcher.file_type("lib/some_file.ex") == :lib
    assert FileWatcher.file_type("lib/.#some_file.ex") == :unknown
  end
end
