# Tomty

Simple [Tomtit](https://github.com/melezhik/Tomtit) Based Test Runner.

# Install

    zef install Tomty

# Usage

    tom --edit test-one

    bash "echo Hello World"

    tom --edit test-two

    bash "echo Upps && exit 1";

    tomty # Runs all test-* scenarios and make report

# Report example

This is a subject to change

    $ tomty

    [test-01] .......
    22:37:14 08/07/2019 [repository] index updated from file:///home/scheck/repo/api/v1/index
    22:37:16 08/07/2019 [bash: echo Hello World] Hello World
    [test-02] .......
    22:37:17 08/07/2019 [repository] index updated from file:///home/scheck/repo/api/v1/index
    22:37:19 08/07/2019 [bash: echo Upps && exit 1] Upps
    22:37:19 08/07/2019 [bash: echo Upps && exit 1] task exit status: 1
    22:37:19 08/07/2019 [bash: echo Upps && exit 1] task bash: echo Upps && exit 1 FAILED
    [test-03] .......
    22:37:19 08/07/2019 [repository] index updated from file:///home/scheck/repo/api/v1/index
    22:37:21 08/07/2019 [bash: echo Hello Again] Hello Again
    =========================================
    )=: (2) tests passed / (1) failed

#  Guide

## Writing test

Tomty test is just a Tomtit scenario, named as `test-*`:


    tom --cat test-meta6-file-exist

    #!perl6

    bash "test -f META6.json"


You can write more advanced tests, for example:

    # Check if perl6.org is accessible

    tom --cat test-perl6-org-alive

    #!perl6

    http-ok("http://perl6.org");

    # Check if META6.json file is a valid json

    tom --cat test-meta6-is-valid-json

    #!perl6

    task-run "meta6 is a valid json", "json-lint";

Check out [Sparrow6 DSL](https://github.com/melezhik/Sparrow6#sparrow6-dsl) on what you can use
writing your tests.

## Running tests

* To run all test just say `tomty`

It will find all the scenarios matching `test-*` pattern and run them in sequence.

* To run single test just say `tom $test`

For example:

    tom test-meta6-is-valid-json

## Examing tests

To list all the tests just say `tom --list|grep test`

This command will list all `test-*` scenarios.

# Tomtu cli

## Options

* `-q`, `--quiet`

Runs tests in quiet mode, only statuses are shown


* `--log`

Get log for given test, useful when running in quiet mode:


    tomty -q
    tomty --log test-01


# See also

* [Sparrow6](https://github.com/melezhik/Sparrow6)

* [Tomtit](https://github.com/melezhik/Tomtit)

# Author

Alexey Melezhik

# Thanks to

God, as my inspiration

