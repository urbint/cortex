defmodule Cortex.ReloaderTest do
  use ExUnit.Case

  alias Cortex.Reloader

  @fixture_path Application.get_env(:cortex, :fixture_path, "test/fixtures")

  defp fixture_for(path) do
    Path.join(@fixture_path, path)
  end

  setup do
    {:ok, initial_state} = Reloader.init([])

    {:ok, state: initial_state}
  end

  describe "recompiles files" do
    test "recompiles a file", %{state: state} do
      path = fixture_for("hello.ex")

      assert ExUnit.CaptureLog.capture_log(fn ->
               {:reply, :ok, _} = Reloader.handle_call({:reload_file, path}, nil, state)
             end) =~ "reloaded test/fixtures/hello.ex"

      assert Hello.hi() == "hello"

      path = fixture_for("hello_2.ex")

      assert ExUnit.CaptureLog.capture_log(fn ->
               {:reply, :ok, _} = Reloader.handle_call({:reload_file, path}, nil, state)
             end) =~ "reloaded test/fixtures/hello_2.ex"

      assert Hello.hi() == "goodbye"
    end

    test "exposes misc errors", %{state: state} do
      error_file_paths = [
        "hello_undefined_type.ex",
        "hello_bad_string.ex",
        "hello_bad_comma.ex",
        "hello_does_not_exist.ex"
      ]

      for path <- error_file_paths do
        assert_errors_found_for_fixture_path(path, state)
      end
    end

    defp assert_errors_found_for_fixture_path(path, state) do
      path = fixture_for(path)

      {:reply, {:error, error_message}, state} =
        Reloader.handle_call({:reload_file, path}, nil, state)

      assert error_message =~ ~r/(CompileError|LoadError|TokenMissingError|SyntaxError)/

      errors_set =
        MapSet.new()
        |> MapSet.put(path)

      assert %{paths_with_errors: ^errors_set} = state
    end
  end
end
