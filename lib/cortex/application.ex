defmodule Cortex.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  alias Cortex.{Controller, Reloader, TestRunner}

  use Application

  def start(_type, _args) do
    cond do
      Mix.env in [:dev, :test] ->
        children =
          if enabled?() do
            children()
          else
            []
          end

        Supervisor.start_link(children, strategy: :one_for_one, name: Cortex.Supervisor)

      true ->
        {:error, "Only :dev and :test environments are allowed"}
    end
  end

  defp children() do
    import Supervisor.Spec, warn: false

    children = [
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

    children ++ env_specific_children
  end


  defp enabled? do
    case Application.get_env(:cortex, :enabled, true) do
      bool when is_boolean(bool) ->
        bool
      {:system, env_var, default} ->
        get_system_var(env_var, default)
      invalid ->
        raise "Invalid config value for Cortex `:enabled`: #{inspect invalid}"
    end
  end

  defp get_system_var(env_var, default) do
    case System.get_env(env_var) do
      nil ->
        default
      truthy when truthy in ["YES", "yes", "true", "TRUE", "1"] ->
        true
      falsey when falsey in ["NO", "no", "false", "FALSE", "0"] ->
        false
      _ ->
        raise "Unparsable Cortex Environment Variable '#{env_var}'"
    end
  end
end
