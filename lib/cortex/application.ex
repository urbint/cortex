defmodule Cortex.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  alias Cortex.{FileWatcher, Controller, Reloader, TestRunner}

  use Application

  def start(_type, _args) do
    cond do
      Mix.env() in [:dev, :test] ->
        children =
          if autostart?() do
            children()
          else
            []
          end

        Supervisor.start_link(children, strategy: :one_for_one, name: Cortex.Supervisor)

      true ->
        {:error, "Only :dev and :test environments are allowed"}
    end
  end

  defp children do
    env_specific_children =
      case Mix.env() do
        :dev ->
          []

        :test ->
          [TestRunner]
      end

    [FileWatcher, Reloader, Controller] ++ env_specific_children
  end

  defp autostart? do
    [enabled, disabled] =
      for {config, default} <- [enabled: true, disabled: false] do
        case Application.get_env(:cortex, config, default) do
          bool when is_boolean(bool) ->
            bool

          {:system, env_var, default} ->
            get_system_var(env_var, default)

          invalid ->
            raise "Invalid config value for Cortex `#{config}`: #{inspect(invalid)}"
        end
      end

    enabled and not disabled
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
