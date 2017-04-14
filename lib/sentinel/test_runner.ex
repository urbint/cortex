defmodule Sentinel.TestRunner do
  @moduledoc false
  use GenServer


  alias Sentinel.Reloader

  @behaviour Sentinel.Controller.Stage

  ##########################################
  # Public API
  ##########################################

  @spec start_link :: GenServer.on_start
  def start_link() do
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
    GenServer.call(__MODULE__, {:run_tests_for_file, path, opts})
  end

  ##########################################
  # Controller Stage Callbacks
  ##########################################
  
  def file_changed(relevant, path) when relevant in [:lib, :test] do
    run_tests_for_file(path)
  end
  def file_changed(_, _), do: :ok



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
        task =
          Task.async(ExUnit, :run, [])

        files_to_load =
          [test_helper(path), test_path]

        files_to_load
        |> Enum.each(&Reloader.reload_file/1)

        ExUnit.Server.cases_loaded()
        Task.await(task, :infinity)

        {:reply, :ok, state}
    end
  end

  defp test_helper(path) do
    if Mix.Project.umbrella? do
      app_name =
        path
        |> String.split("/")
        |> Enum.at(1)

      "apps/#{app_name}/test/test_helper.exs"
    else
      "test/test_helper.exs"
    end
  end
end
