#!perl6

my $msg = prompt("message: ");

my %state = task-run "get branch", "git-current-branch";

task-run "commit my changes", "git-commit", %( message => "[{%state<branch>}] $msg" );

