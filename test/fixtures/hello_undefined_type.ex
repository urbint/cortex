defmodule Hello do
  @moduledoc """
  Fixture that fails because the type is undefined.

  """

  @spec hi(undefined_type) :: binary
  def hi, do: "fail"
end
