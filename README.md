# <img src='https://storage.googleapis.com/ub-public/cortex_logo.png' height='60'>
[![CircleCI](https://circleci.com/gh/urbint/cortex/tree/master.svg?style=svg)](https://circleci.com/gh/urbint/cortex/tree/master)

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


### Umbrella Applications

If you're running an umbrella application, add Cortex to the dependencies of
each of the sub-apps that you would like Cortex to monitor. Do this instead
of adding it as a dependency in the root `mix.exs` file.

This is necessary because dependencies in the root `mix.exs` in umbrella
application are not automatically started, which is a process that Cortex
depends on.



## Usage

Cortex runs automatically along-side your mix app.

```sh
iex -S mix
```

This is enough to get live-reload on file change when editing your app.

### Commands

Some commands intended to be used via the shell are provided in the `Cortex`
module:

- `Cortex.all` - run all stages (currently reload and test runner) on all files
  in the project

- `Cortex.focus` - filter test runs to only tests matching the given pattern.
  Supports:
  - a regular expression, which will filter to tests whose full test name
    matches that regular expression
  - a string, which will compile as a regular expression and behave like the
    above regular expression
  - an integer, which will filter by line number for tests
  - a keyword, which will pass through to the `include` option of
    `ExUnit.configure/1` unchanged

- `Cortex.unfocus` - clear the currently configured focus


### Test Runner

When you run your app with `MIX_ENV=test`,
Cortex will automatically run tests for saved `test` files,
as well as tests paired with saved files in `lib`.

```sh
MIX_ENV=test iex -S mix
```


## Enabling and Disabling

Whether cortex runs at all can be configured via the configuration of your
application. By default cortex does run.

```ex
config :cortex,
  enabled: false
```

Cortex also supports the Elixir / Erlang convention of a
`{:system, ENV_VAR_NAME, default_value}` in the config file.


For example, if you wanted to have cortex disabled in your project by default,
you could add the following to your `config.exs`:

```ex
config :cortex,
  enabled: {:system, "CORTEX_ENABLED", false}
```

Then, to run cortex you would start `iex` with the following options:

```
CORTEX_ENABLED=true iex -S mix
```


## Phoenix

If you are running a phoenix application,
make sure you are running the app in interactive mode:

```sh
iex -S mix phoenix.server
```


## Roadmap

 - [x] Reload Modules
 - [x] Rerun tests
 - [x] Reload all modules and run all tests from the IEx shell
 - [ ] Reload and run tests for a specific module from the IEx shell
 - [ ] [Credo](https://github.com/rrrene/credo) runner
 - [ ] [Dialyzer](https://github.com/jeremyjh/dialyxir/) runner
 - [ ] [ExDash](https://github.com/urbint/ex_dash) runner
 - [ ] Auto-formatting runner
 - [ ] Custom mix task runner
 - [x] Cortex 'focus' mode
 - [ ] Broader OTP reload support
 - [ ] Autofetch dependencies when `mix.exs` changes `deps`


## License

This software is licensed under [the MIT license](LICENSE.md).
