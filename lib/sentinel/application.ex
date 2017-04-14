defmodule Sentinel.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  alias Sentinel.{FileWatcher,Controller}

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    cond do
      Mix.env in [:dev, :test] ->
        children = [
          FileWatcher.child_spec,
          worker(Controller, [])
        ]

        opts = [strategy: :one_for_one, name: Sentinel.Supervisor]
        Supervisor.start_link(children, opts)

      true ->
        {:error, "Only :dev and :test environments are allowed"}
    end
  end
end
