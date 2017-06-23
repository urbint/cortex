# <img src='https://storage.googleapis.com/ub-public/cortex_logo.png' height='60'>

Cortex watches your Elixir files and automatically runs tests for newly
updated modules.


## Installation

Getting started with Cortex is easy. Add the following to your `mix.exs` file:

```elixir
def deps do
  [{:cortex, git: "git@github.com:urbint/cortex.git"}]
end
```


## Umbrella Applications

If you're running an umbrella application, add Cortex to the dependencies of
each of the sub-apps that you would like Cortex to monitor. Do this instead
of adding it as a dependency in the root `mix.exs` file.

This is necessary because dependencies in the root `mix.exs` in umbrella
application are not automatically started, which is a process that Cortex
depends on.
