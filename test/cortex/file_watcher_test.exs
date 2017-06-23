defmodule Cortex.FileWatcherTest do
  use ExUnit.Case

  alias Cortex.FileWatcher

  test "file_type" do
    assert FileWatcher.file_type("test/some_file.exs") == :test
    assert FileWatcher.file_type("lib/some_file.ex") == :lib
    assert FileWatcher.file_type("lib/.#some_file.ex") == :unknown
  end
end
