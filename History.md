
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
