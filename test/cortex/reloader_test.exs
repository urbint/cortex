defmodule Cortex.ReloaderTest do
  use ExUnit.Case

  alias Cortex.Reloader

  @fixture_path Application.get_env(:cortex, :fixture_path, "test/fixtures")

  defp fixture_for(path) do
    Path.join(@fixture_path, path)
  end


  describe "reload_file/1" do
    test "loads a file from a path" do
      path =
        fixture_for("hello.ex")

      assert :ok = Reloader.reload_file(path)
      assert Hello.hi() == "hello"

      path =
        fixture_for("hello_2.ex")

      assert :ok = Reloader.reload_file(path)
      assert Hello.hi() == "goodbye"
    end

    test "exposes a compilation error" do
      path = fixture_for("hello_compile_fail.ex")

      {:error, reason} =
        Reloader.reload_file(path)

      assert String.contains?(reason, "spec for undefined function")
    end
  end

end
