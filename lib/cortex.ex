defmodule Cortex do
  @moduledoc """
  Documentation for Cortex.

  ## Features

  Cortex runs along side your elixir application.

  ### Reload

  Once added to your dependencies, it will startup automatically
  when you run `iex -S mix`.

    ```
    $ iex -S mix
    ```

  A file-watcher will keep an eye on any changes made
  in your app's `lib` and `test` directories,
  recompiling the relevant files as changes are made.

  #### Compile Failures

  Changes to a file that result in a failed compile are pretty annoying
  to deal with. Cortex will present compiler errors (with the file and line number!)
  until a clean compile is again possible.

  ### Test Runner

  When your app is run in the :test env,
  Cortex will act as a test runner.

    ```
    $ MIX_ENV=test iex -S mix
    ```

  Any change to a file in `lib` will then run tests for the
  corresponding file in `test`, and any change to a test file
  will re-run that file's tests.

  """

  @doc """
  Run all stages in the current Cortex pipeline on all files (ie, recompile all
  files, run all tests, etc.).

  """
  defdelegate all, to: Cortex.Controller, as: :run_all


  @doc """
  Set the current focus for all Cortex stages to which it applies.

  Allowed arguments are:

  - a `Regex`, which will filter to tests whose full test name matches that regular expression
  - a string, which will compile as a regular expression and behave like the above regular
    expression
  - an integer, which will filter by line number for tests
  - a keyword, which will pass through to `ExUnit.configure/1` unchanged

  """
  def focus(%Regex{} = re),
    do: Cortex.Controller.set_focus(test: re)

  def focus(string) when is_binary(string),
    do: string |> Regex.compile!() |> focus()

  def focus(integer) when is_integer(integer),
    do: Cortex.Controller.set_focus(line: integer)

  def focus(focus),
    do: Cortex.Controller.set_focus(focus)


  @doc """
  Clear the focus for all Cortex stages.

  """
  defdelegate unfocus, to: Cortex.Controller, as: :clear_focus

end
