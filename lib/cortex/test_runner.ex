defmodule Cortex.TestRunner do
  @moduledoc """
  `Cortex.Controller.Stage` module responsible for running a changed file's associated tests.

  See the `Cortex.Controller.Stage`module for more information about Cortex's stages.

  """

  alias Cortex.Reloader
  alias Cortex.Controller.Stage

  use GenServer

  @behaviour Stage



  ##########################################
  # Public API
  ##########################################

  @spec start_link :: GenServer.on_start
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end


  @doc """
  Resolves `path` to the associated test file.

  If `path` is already pointing to a test file, then `path` is returned to the caller unaltered.

  """
  @spec test_file_for_path(Path.t) :: Path.t | :not_found
  def test_file_for_path(path) do
    is_test_file? =
      Regex.match?(~r/test\//, path) and String.ends_with?(path, ".exs")

    is_lib_file? =
      Regex.match?(~r/lib\//, path) and String.ends_with?(path, ".ex")

    cond do
      is_test_file? ->
        path

      is_lib_file? ->
        test_path =
          path
          |> String.replace("lib/", "test/")
          |> String.replace(".ex", "_test.exs")

        if File.exists?(test_path) do
          test_path
        else
          :not_found
        end

      true ->
        :not_found
    end
  end


  @doc """
  Runs the tests associated with the file pointed to by `path`.

  This function is invoked when a file-change event is received.

  """
  @spec run_tests_for_file(Path.t) :: :ok | {:error, String.t}
  def run_tests_for_file(path) do
    GenServer.call(__MODULE__, {:run_tests_for_file, path}, :infinity)
  end



  ##########################################
  # Controller Stage Callbacks
  ##########################################

  @impl Stage
  def file_changed(relevant, path) when relevant in [:lib, :test],
    do: run_tests_for_file(path)

  def file_changed(:unknown, _path),
    do: :ok


  @impl Stage
  def cancel_on_error?, do: false



  ##########################################
  # GenServer Callbacks
  ##########################################

  @impl GenServer
  def init(_) do
    Application.ensure_started(:ex_unit)
    {:ok, %{}}
  end


  @impl GenServer
  def handle_call({:run_tests_for_file, path}, _from, state) do
    case test_file_for_path(path) do
      :not_found ->
        {:reply, :ok, state}

      test_path ->
        files_to_load =
          [test_helper(path), test_path]

        compiler_errors =
          files_to_load
          |> Stream.map(&Reloader.reload_file/1)
          |> Enum.reject(&(&1 == :ok))

        with [] <- compiler_errors do
          task =
            Task.async(ExUnit, :run, [])

          ExUnit.Server.cases_loaded()
          Task.await(task, :infinity)

          {:reply, :ok, state}
        else
          errors ->
            compiler_error_descs =
              errors
              |> Stream.map(&elem(&1, 1))
              |> Enum.join("\n")

            {:reply, {:error, compiler_error_descs}, state}
        end
    end
  end



  ##########################################
  # Private Helpers
  ##########################################

  @spec test_helper(Path.t) :: Path.t
  defp test_helper(path) do
    if Mix.Project.umbrella? do
      app_name =
        path
        |> Path.relative_to_cwd
        |> String.split("/")
        |> Enum.at(1)

      "apps/#{app_name}/test/test_helper.exs"
    else
      "test/test_helper.exs"
    end
  end
end
