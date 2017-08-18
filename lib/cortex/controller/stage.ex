defmodule Cortex.Controller.Stage do
  @moduledoc """
  Behaviour module defining the callbacks a Cortex Controller Stage must implement.

  A controller stage is a step in a pipeline that Cortex runs after receiving a notification that a
  file has changed.

  """

  alias Cortex.FileWatcher



  ##########################################
  # Callback Definitions
  ##########################################

  @doc """
  Invoked any time a file is changed by the file watcher.

  The first argument is the type of the file (`:lib`, `:test`, or `:unknown`),
  and the second is the path of the file.

  """
  @callback file_changed(FileWatcher.file_type, Path.t) :: :ok | {:error, any}


  @doc """
  Returns a boolean for whether or not an error should cause the rest of the pipeline to fail.

  """
  @callback cancel_on_error? :: boolean

end
