# Tomty

Tomty - Simple Perl6 Test Runner.

# Install

    zef install Tomty

# Usage

    tomty --edit test-01

    bash "echo Hello World"

    tom --edit test-02

    bash "echo Upps && exit 1";

    tomty --edit test-03

    bash "echo Hello Again!";

    tomty --run -q # Runs all test-* scenarios and make reports

    [1] / [test-01] .......  2 sec. OK
    [2] / [test-02] .......  3 sec. FAIL
    [3] / [test-03] .......  3 sec. OK
    =========================================
    )=: (2) tests passed / (1) failed
    


    echo ".cache" >> .gitignore

    git add .tomty

#  Guide

## Writing test

Tomty test is just a Sparrow6 scenario, named as `test-*`:


    tomty --edit test-meta6-file-exist

    #!perl6

    bash "test -f META6.json"


You can write more advanced tests, for example:

    # Check if perl6.org is accessible

    tomty --edit test-perl6-org-alive

    #!perl6

    http-ok("http://perl6.org");

    # Check if META6.json file is a valid json

    tomty --edit test-meta6-is-valid-json

    #!perl6

    task-run "meta6 is a valid json", "json-lint";

Check out [Sparrow6 DSL](https://github.com/melezhik/Sparrow6#sparrow6-dsl) on what you can use
writing your tests.

## Running tests

* To run all test just say `tomty --run`

It will find all the scenarios matching `test-*` pattern and run them in sequence.

* To run single test just say `tomty --run $test`

For example:

    tomty --run test-meta6-is-valid-json

## Examing tests

To list all the tests just say `tomty --list`

This command will list all test scenarios.

# Tomtu cli

## Options

* `-q`, `--quiet`

Runs tests in quiet mode, only statuses are shown


* `--log`

Get log for given test run, useful when running in quiet mode:


    tomty -q
    tomty --log 03


# See also

* [Sparrow6](https://github.com/melezhik/Sparrow6)

* [Tomtit](https://github.com/melezhik/Tomtit)

# Author

Alexey Melezhik

# Thanks to

God, as my inspiration

