defmodule Cortex.TestRunner do
  @moduledoc false
  use GenServer

  alias Cortex.Reloader
  alias ExUnit.Server, as: ExUnitServer
  alias Mix.Project, as: MixProject

  @behaviour Cortex.Controller.Stage

  ##########################################
  # Public API
  ##########################################

  @spec start_link :: GenServer.on_start
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end


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


  @spec run_tests_for_file(Path.t, keyword) :: :ok | {:error, String.t}
  def run_tests_for_file(path, opts \\ []) do
    GenServer.call(__MODULE__, {:run_tests_for_file, path, opts}, :infinity)
  end

  ##########################################
  # Controller Stage Callbacks
  ##########################################

  @spec run_all :: :ok | {:error, String.t}
  def run_all do
    GenServer.call(__MODULE__, :run_all, :infinity)
  end

  def file_changed(relevant, path) when relevant in [:lib, :test] do
    if not dep_path?(path) do
      run_tests_for_file(path)
    else
      :ok
    end
  end
  def file_changed(_, _), do: :ok

  def cancel_on_error?, do: false


  ##########################################
  # GenServer Callbacks
  ##########################################

  def init(_) do
    Application.ensure_started(:ex_unit)
    {:ok, %{}}
  end


  def handle_call({:run_tests_for_file, path, _opts}, _from, state) do
    case test_file_for_path(path) do
      :not_found ->
        {:reply, :ok, state}

      test_path ->
        case run_test_files([test_path]) do
          :ok ->
            {:reply, :ok, state}

          err = {:error, _} ->
            {:reply, err, state}
        end
    end
  end

  def handle_call(:run_all, _from, state) do
    case run_test_files() do
      :ok ->
        {:reply, :ok, state}

      err = {:error, _} ->
        {:reply, err, state}
    end
  end


  def run_test_files, do: run_test_files(all_test_files())
  def run_test_files([]), do: :ok
  def run_test_files(files) do
    files
    |> Enum.group_by(&test_helper/1)
    |> Enum.map(fn {helper, files} -> run_test_files(helper, files) end)
    |> Enum.find(:ok, fn
      :ok         -> false
      {:error, _} -> true
    end)
  end


  @spec run_test_files(Path.t, [Path.t]) :: :ok | {:error, [any]}
  def run_test_files(_test_helper, []), do: :ok
  def run_test_files(test_helper, files) do
    files_to_load =
      [test_helper | files]

    compiler_errors =
      files_to_load
      |> Stream.map(&Reloader.reload_file/1)
      |> Enum.reject(&(&1 == :ok))

    with [] <- compiler_errors do
      task =
        Task.async(ExUnit, :run, [])

      ExUnitServer.cases_loaded()

      Task.await(task, :infinity)

      :ok
    else errors ->
      compiler_error_descs =
        errors
        |> Stream.map(&elem(&1, 1))
        |> Enum.join("\n")

      {:error, compiler_error_descs}
    end
  end

  defp all_test_files do
    if MixProject.umbrella?() do
      MixProject.apps_paths()
      |> Stream.flat_map(fn {_app, path} ->
        path
        |> Path.join("test")
        |> test_files_in_dir()
      end)
    else
      test_files_in_dir("test")
    end
  end

  defp test_files_in_dir(dir) do
    dir
    |> Path.join("**/*_test.exs")
    |> Path.wildcard
  end

  defp test_helper(path) do
    if MixProject.umbrella? do
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


  # Returns true if the path is a dependency of the current application
  @spec dep_path?(Path.t) :: boolean
  defp dep_path?(path) do
    cond do
      path =~ ~r/\/deps\// ->
        true

      MixProject.umbrella? ->
        not(path =~ ~r/\/apps\//)

      true ->
        app_root =
          MixProject.app_path()
          |> String.replace(~r/_build.*/, "")

        not(path |> String.contains?(app_root))
    end
  end
end
