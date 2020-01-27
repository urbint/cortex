Unreleased
==========

  * feat: File throttling to prevent files being compiled multiple times in quick succession and tests being run multiple times due to one "change".

0.5.0 / 2018-05-01
==================

  * feat: Elixir 1.6 support
  * chore(test_runner): make credo pass
  * fix(reloader): handle KeyError.t
  * fix(reloader): handle undefined function error
  * build(ci): Add configuration for CircleCI
  * build(): install inotify-tools in CI
  * docs(): Add CircleCI status badge
  * build(): Add CircleCI config
  * chore(): Add Dialyzer and fix all errors
  * chore(): Add Credo and fix all errors

0.4.2 / 2017-09-20
==================

  * fix(): Clear the focus before loading test helper if it's not set

0.4.0 / 2017-09-19
==================

  * feat(focus): Implement `Cortex.focus`

0.3.1 (2017-09-17)
==================

  * feat(file_watcher): adds dependency directories to the file watcher
  * fix(reloader): rescue catches more errors, displays better compile-fail messages
  * fix(test_runner): skip re-running tests for dependencies
  * fix(test_runner): fix bad return value error

0.3.0 / 2017-09-10
==================

   * feat(reloader): adds a debug log when all compiler errors are resolved
   * `Cortex.all/0`: run all files for all pipeline stages
   * refactor(file_watcher): updated to use new file_system api
   * chore(): Favors infinite timeouts for pipeline

0.2.0 / 2017-06-30
==================

   * feat(config): allow enabling and disabling of cortex via config and env_var
