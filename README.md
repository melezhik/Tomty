# Tomty

Tomty - Raku Test Framework.

# Install

    zef install Tomty

# Build Status

[![SparkyCI](https://ci.sparrowhub.io/project/gh-melezhik-Tomty/badge)](https://ci.sparrowhub.io)

# Quick start

    tomty --edit test-01

    bash "echo Hello World"

    tomty --edit test-02

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

Tomty test is just a Raku scenario:

    tomty --edit test-meta6-file-exist

    #!raku

    bash "test -f META6.json"

You can write more advanced tests, for example:

    # Check if raku.org is accessible

    tomty --edit test-raku-org-alive

    #!raku

    http-ok("https://raku.org");

    # Check if META6.json file is a valid json

    tomty --edit test-meta6-is-valid-json

    #!raku

    task-run "meta6 is a valid json", "json-lint";

Check out [Sparrow6 DSL](https://github.com/melezhik/Sparrow6#sparrow6-dsl) on what you can use writing your tests.

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

* Tomty environments are configuration files, written on Raku and technically speaking are plain Raku Hashes

* Environment configuration files should be placed at `.tomty/conf` directory:

`.tomty/env/config.raku`:

```raku
{
    dbname => "products",
    dbhost => "localhost"
}
```

When tomty runs it picks the `.tomty/env/config.raku` and read configuration from it
variables will be accessible as `config` Hash, inside Tomty scenarios:

```raku
my $dbname = config<dbname>;
my $dbhost = config<dbhost>;
```

To define _named_ configuration ( environment ), simply create `.tomty/env/config{$env}.raku` file and refer to it through
`--env=$env` parameter:

    nano .tomty/env/config.prod.raku

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

```raku
=begin tomty
%(
    tag => "slow"
)
=end tomty
```

Macros could be any Raku code, returning `Hash`. The example above set tag=`slow` for slow running tests,
you can skip test execution by using `--skip` option:

    tomty --skip=slow

See also `tags filtering`.

Tags could be multiple as well:

```raku
=begin tomty
%(
    tag => [ "flaky", "slow" ]
)
=end tomty
```

## Tags filtering

Tags filtering allows to run subsets of scenarios using tags as criteria.

### Logical OR

By default logical OR is implied when using comma:

Examples:

    tomty --skip=slow,windows # skip slow OR windows tests

    tomty --only=frontend,backend # only frontend OR backend test

### Logical AND 

Use `+` to mimic logical AND:

    tomty --only=database+mysql # execute only mysql database tests

`--skip` and `--only` could be combined to get more sophisticated scenarios:

    tomty --only=database+mysql,skip=window # execute only mysql database tests BUT not for windows OS system

## List tags

One can list available tags by:

    tomty --list --tags

You can combine `--tags` with `--only` or `--skip` options to _list_ tagged tests.

Examples:

    tomty --tags --only=foo  # list tests tagged by `foo`

    tomty --tags --only=foo+bar  # list tests tagged by `foo` AND `bar`

    tomty --tags --only=foo,bar  # list tests tagged by `foo` OR `bar`


## Profiles

Tomty profile sets command line arguments for a named profile:

    cat .tomty/profile

```raku
%(
    default => %(
        skip => "broken"
    )
)
```

One can override following command line arguments through a profile:

* `skip`
* `only`
* `env`
* `no-index-update`

In the future more arguments will be supported.

A `default` profile sets default command line arguments when `tomty` cli run.

To add more profiles just add more Hash keys and define proper settings:

```raku
%(
    default => %(
        skip => "broken"
    ),
    development => %(
        only => "new-bugs"
    )
)
```
To chose profile use `--profile` option:

    tomty --profile development

## Bash completion

Tomty comes with nice Bash completion to easy cli usage, use `--completion` option to install completion:

    tomty --completion

And then `source ~/.tomty_completion.sh` to activate one.

# Tomty cli

## Options

* `--all|-a`

Run all tests

* `--show-failed`

Show failed tests

* `--verbose`

Runs tests in verbose mode, print more details about every test

* `--no-index-update`

Don't update Sparrow repository index

* `--dump-task`

Dump task code before execution, see SP6_DUMP_TASK_CODE Sparrow documentation

* `--color`

Run in color mode

* `--list`

List tests/tags

To list test only:

    tomty --list

To lists tags only:

    tomty --list --tags

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


* `--skip` | `--only`

Set tags filters.

Skip tests tagged as `slow`

    tomty --skip=slow

Only run tests tagged as `linux`

    tomty --only=linux

See also `tags filtering` for more details on tag filtering.

* `--tags`

Show available tags:

    tomty --list --tags # list all tags

You can combine `--tags` with `--only` or `--skip` options:

    tomty --tags --only=foo+bar  # list tests tagged by `foo` AND `bar`

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
