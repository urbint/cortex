defmodule Sentinel.FileWatcher.WorkerTest do
  use ExUnit.Case

  alias Sentinel.FileWatcher.Worker

  test "file_type" do
    assert Worker.file_type("test/some_file.exs") == :test
    assert Worker.file_type("lib/some_file.ex") == :lib
    assert Worker.file_type("lib/.#some_file.ex") == :unknown
  end
end
