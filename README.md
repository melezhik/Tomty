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

    tomty --all # Run all tests and make reports

    [1/3] / [test-01] .......  2 sec. OK
    [2/3] / [test-02] .......  3 sec. FAIL
    [3/3] / [test-03] .......  3 sec. OK
    =========================================
    )=: (2) tests passed / (1) failed

    # save tests to Git

    echo ".tomty/.cache" >> .gitignore

    git add .tomty

#  Guide

## Writing tests

Tomty test is just a Sparrow6 scenario:

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

* To run all test just say `tomty --all`

It will find all the tests and run them in sequence.

* To run single test just say `tomty $test`

For example:

    tomty test-meta6-is-valid-json

## Examining tests

To list all the tests just say `tomty --list`

This command will list all tests.

## Managing tests

### Removing test

To remove test use `--remove` option:

    tomty --remove $test

### Edit test source code

Use `--edit` to create test from the scratch or to edit existed test source code:

    tomty --edit $test

### Getting test source code

Use `--cat` command to print out test source code:

    tomtit --cat $test

Use `--lines` flag to print out test source code with line numbers.

# Environments

* Tomty environments are configuration files, written on Perl6 and technically speaking are plain Perl6 Hashes

* Environment configuration files should be placed at `.tomty/conf` directory:

`.tomty/env/config.pl6`:

    {
        dbname => "products",
        dbhost => "localhost"

    }

When tomty runs it picks the `.tomty/env/config.pl6` and read configuration from it 
variables will be accessible as `config` Hash, inside Tomty scenarios:


    my $dbname = config<dbname>;
    my $dbhost = config<dbhost>;


To define _named_ configuration ( environment ), simply create `.tomty/env/config{$env}.pl6` file and refer to it through
`--env=$env` parameter:

    nano .tomty/env/config.prod.pl6

    tomty --env=prod ... other parameters here # will run with production configuration

You can run editor for environment configuration by using --edit option:

    tomty --env-edit test    # edit test environment configuration

    tomty --env-edit default # edit default configuration

You can activate environment by using `--env-set` parameter:

    tomty --env-set prod    # set prod environment as default
    tomty --env-set         # to list active (current) environment
    tomty --env-set default # to set current environment to default

To view environment configuration use `--env-cat` command:

    tomty --env-cat $env

Use `--lines` flag to print out environment source code with line numbers.

You print out the list of all environments by using `--env-list` parameters:

    tomty --env-list

## Macros

Tomty macros allow to pre-process test scenarios. To embed macros use `=begin tomty` .. `=end tomty` syntax:

    =begin tomty
    %(
      tag => "slow"
    )
    =end tomty

Macros could be any Perl6 code, returning `Hash`. The example above set tag=`slow` for slow running tests,
you can skip test execution by using `--skip` option:

    tomty --skip=slow

## Bash completion

Tomty comes with nice Bash completion to easy cli usage, use `--completion` option to install completion:

    tomty --completion

And then `source ~/.tomty_completion.sh` to activate one.

# Tomty cli

## Options

* `--all|-a`

Run all tests

* `--show-failed`

Show failed tests. Usefull

* `--verbose`

Runs tests in verbose mode, print more details about every test

* `--list`

List tests

* `--noheader`

Omit header when list tests. Allow to edit tests one by one:


    for i in $(tomty --noheader); do tomty --edit $i; done


* `--edit|--cat|--remove`

Edit, dump, remove test

* `--env-edit|--env-list|--env-set`

Edit, list, set environment

* `--completion`

Install Tomty Bash completion

* `--log`

Get log for given test run, useful when running in all tests mode:

    tomty -all

    tomty --log test-01

* `--skip`

Conditionally skip tagged tests:

    tomty --all --skip=slow

* `--only`

Conditionally run only tagged tests:

    tomty --only=database

# Environment variables

* `TOMTY_DEBUG`

Use it when debugging Tomty itself:

    TOMTY_DEBUG=1 tomty --all

# See also

* [Sparrow6](https://github.com/melezhik/Sparrow6)

* [Tomtit](https://github.com/melezhik/Tomtit)

# Author

Alexey Melezhik

# Thanks to

God, as my inspiration

