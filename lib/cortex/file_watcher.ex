defmodule Cortex.FileWatcher do
  @moduledoc """
  Module responsible for listening to filesystem events and broadcasting them to the rest of the
  application.

  """

  alias Cortex.Controller

  use ExFSWatch, dirs: ["lib/", "test/", "apps/"] |> Enum.filter(&File.dir?/1)



  ##########################################
  # Types
  ##########################################

  @type file_type :: :lib | :test | :unknown



  ##########################################
  # ExFSWatch Callbacks
  ##########################################

  # would be @impl ExFSWatch, but __using__/1 macro does not enforce the behaviour
  def callback(:stop), do: :ok

  def callback(path, _events) do
    GenServer.cast(Controller, {:file_changed, file_type(path), path})
  end



  ##########################################
  # Private Helpers
  ##########################################

  @spec file_type(Path.t) :: file_type
  defp file_type(path) do
    is_elixir_file? =
      Regex.match?(~r/\/(\w|_)+\.exs?/, path)

    cond do
      is_elixir_file? and Regex.match?(~r/lib\//, path) ->
        :lib

      is_elixir_file? and Regex.match?(~r/test\//, path) ->
        :test

      true ->
        :unknown
    end
  end

end
