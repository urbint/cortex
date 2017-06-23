defmodule Cortex.ReloaderTest do
  use ExUnit.Case

  alias Cortex.Reloader

  @fixture_path Application.get_env(:cortex, :fixture_path, "test/fixtures")

  defp fixture_for(path) do
    Path.join(@fixture_path, path)
  end

  describe "recompiles files" do
    test "recompiles a file" do
      path = fixture_for("hello.ex")

      {:reply, :ok, _} =
        Reloader.handle_call({:reload_file, path}, nil, %{})

      assert Hello.hi() == "hello"

      path = fixture_for("hello_2.ex")

      {:reply, :ok, _} =
        Reloader.handle_call({:reload_file, path}, nil, %{})

      assert Hello.hi() == "goodbye"
    end

    test "exposes a compilation error" do
      path = fixture_for("hello_compile_fail.ex")

      {:reply, {:error, desc}, _} =
        Reloader.handle_call({:reload_file, path}, nil, %{})

      assert Regex.match?(~r/spec for undefined function/, desc)
    end
  end
end
