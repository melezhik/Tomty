# Tomty

Simple [Tomtit](https://github.com/melezhik/Tomtit) Based Test Runner.

# Install

    zef install https://github.com/melezhik/Tomtit.git # The latest GH version is required
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

# See also

[Tomtit](https://github.com/melezhik/Tomtit)

# Author

Alexey Melezhik

# Thanks to

God, as my inspiration


# Tomty
