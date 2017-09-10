defmodule Cortex.ReloaderTest do
  use ExUnit.Case

  alias Cortex.Reloader

  @fixture_path Application.get_env(:cortex, :fixture_path, "test/fixtures")

  defp fixture_for(path) do
    Path.join(@fixture_path, path)
  end

  setup do
    {:ok, initial_state} =
      Reloader.init([])

    {:ok, state: initial_state}
  end

  describe "recompiles files" do
    test "recompiles a file", %{state: state} do
      path = fixture_for("hello.ex")

      {:reply, :ok, _} =
        Reloader.handle_call({:reload_file, path}, nil, state)

      assert Hello.hi() == "hello"

      path = fixture_for("hello_2.ex")

      {:reply, :ok, _} =
        Reloader.handle_call({:reload_file, path}, nil, state)

      assert Hello.hi() == "goodbye"
    end

    test "exposes a compilation error", %{state: state} do
      path = fixture_for("hello_compile_fail.ex")

      {:reply, {:error, desc}, state} =
        Reloader.handle_call({:reload_file, path}, nil, state)


      assert Regex.match?(~r/spec for undefined function/, desc)

      errors_set =
        MapSet.new()
        |> MapSet.put(path)

      assert %{paths_with_errors: errors_set} = state
    end
  end
end
