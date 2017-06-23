defmodule Cortex.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  alias Cortex.{FileWatcher,Controller,Reloader,TestRunner}

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    cond do
      Mix.env in [:dev, :test] ->
        children = [
          FileWatcher.child_spec,
          worker(Reloader, []),
          worker(Controller, [])
        ]

        env_specific_children =
          case Mix.env do
            :dev ->
              []
            :test ->
              [worker(TestRunner, [])]
          end

        opts = [strategy: :one_for_one, name: Cortex.Supervisor]

        Supervisor.start_link(children ++ env_specific_children, opts)

      true ->
        {:error, "Only :dev and :test environments are allowed"}
    end
  end
end
