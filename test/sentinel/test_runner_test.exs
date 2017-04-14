defmodule Sentinel.TestRunnerTest do
  use ExUnit.Case

  import Sentinel.TestRunner

  describe "test_file_for_path/1" do
    test "returns the path itself if it is a test file" do
      assert test_file_for_path("test/sentinel/test_runner_test.exs") ==
        "test/sentinel/test_runner_test.exs"
    end

    test "returns the path for a test file if it exists" do
      assert test_file_for_path("lib/sentinel/test_runner.ex") ==
        "test/sentinel/test_runner_test.exs"
    end

    test "returns :not_found if no test can be found" do
      assert test_file_for_path("lib/something.ex") ==
        :not_found
    end
  end
end
