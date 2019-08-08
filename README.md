# Tomty

Simple [Tomtit](https://github.com/melezhik/Tomtit) Based Test Runner.

# Install

    zef install Tomty

# Usage

    tom --edit test-01

    bash "echo Hello World"

    tom --edit test-02

    bash "echo Upps && exit 1";

    tom --edit test-03

    bash "echo Hello Again!";

    tomty -q # Runs all test-* scenarios and make reports

    [test-01] .......  3 sec. OK
    [test-02] .......  3 sec. FAIL
    [test-03] .......  3 sec. OK
    [test-meta6-file-exist] .......  2 sec. OK
    [test-meta6-is-valid-json] .......  2 sec. OK
    =========================================
    )=: (4) tests passed / (1) failed


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

