# <img src='https://storage.googleapis.com/ub-public/cortex_logo.png' height='60'>

Cortex is the intelligent coding assistant for Elixir.

- Compiles and reloads modified files
- Automatically runs the appropriate tests at the appropriate time
- Accepts pluggable adapters for custom builds


## Demo

# <img src='http://files.slingingcode.com/113N1q2n2e0Q/small.gif'>



## Installation

Getting started with Cortex is easy. Add the following to your `mix.exs` file:

```elixir
def deps do
  [
    {:cortex, "~> 0.1", only: [:dev, :test]},
  ]
end
```


## Usage

Cortex runs automatically along-side your mix app.

```sh
iex -S mix
```

This is enough to get live-reload on file change when editing your app.

### Test Runner

When you run your app with `MIX_ENV=test`,
Cortex will automatically run tests for saved `test` files,
as well as tests paired with saved files in `lib`.

```sh
MIX_ENV=test iex -S mix
```


## Umbrella Applications

If you're running an umbrella application, add Cortex to the dependencies of
each of the sub-apps that you would like Cortex to monitor. Do this instead
of adding it as a dependency in the root `mix.exs` file.

This is necessary because dependencies in the root `mix.exs` in umbrella
application are not automatically started, which is a process that Cortex
depends on.

## Roadmap

 - [x] Reload Modules
 - [x] Rerun tests
 - [ ] [Credo](https://github.com/rrrene/credohttps://github.com/rrrene/credo) runner
 - [ ] [Dialyzer](https://github.com/jeremyjh/dialyxir/) runner
 - [ ] [ExDash](https://github.com/urbint/ex_dash) runner
 - [ ] Custom mix task runner
 - [ ] Cortex 'focus' mode
 - [ ] Broader OTP reload support
