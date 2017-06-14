defmodule Hello do
  @moduledoc """
  Fixture that compiles just fine.

  """

  @spec hi(undefined_type) :: binary
  def hi, do: "fail"
end
