# Sentinel

Sentinel watches your Elixir files and automatically runs tests for newly 
updated modules.


## Installation

Getting started with Sentinel is easy. Add the following to your `mix.exs` file:

```elixir
def deps do
  [{:sentinel, git: "git@github.com:urbint/sentinel.git"}]
end
```


## Umbrella Applications

If you're running an umbrella application, add Sentinel to the dependencies of 
each of the sub-apps that you would like Sentinel to monitor. Do this instead 
of adding it as a dependency in the root `mix.exs` file.

This is necessary because dependencies in the root `mix.exs` in umbrella 
application are not automatically started, which is a process that Sentinel
depends on.
