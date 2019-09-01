defmodule Hello do
  @moduledoc """
  Fixture with a struct field referenced that does not exist.

  """

  defstruct [
    :field_a
  ]

  def hi() do
    b = %Hello{field_b: "blah"}

    b
  end
end
