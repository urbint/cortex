defmodule Sentinel.FileWatcher.Worker do
  @moduledoc false

  alias Sentinel.FileWatcher

  use ExFSWatch, dirs: ["lib/", "test/", "apps/"]

  def callback(:stop), do: :ok

  def callback(path, _events) do
    GenServer.cast(FileWatcher, {:file_changed, file_type(path), path})
  end


  def file_type(path) do
    is_elixir_file? =
      Regex.match?(~r/\/(\w|_)+\.exs?/, path)

    cond do
      is_elixir_file? and Regex.match?(~r/test/, path) ->
        :test

      is_elixir_file? and Regex.match?(~r/lib/, path) ->
        :lib

      true ->
        :unknown
    end
  end
end
