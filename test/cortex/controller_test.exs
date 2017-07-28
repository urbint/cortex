defmodule Cortex.ControllerTest do
  use ExUnit.Case

  alias Cortex.Controller

  test "file_type" do
    assert Controller.file_type("test/some_file.exs") == :test
    assert Controller.file_type("lib/some_file.ex") == :lib
    assert Controller.file_type("lib/.#some_file.ex") == :unknown
  end
end
