#!perl6

use v6;

unit module Tomty:ver<0.0.1>;

use Sparrow6::Task::Repository;

use Sparrow6::DSL;

use YAMLish;

use File::Directory::Tree;

# tomty cli initializer

sub reports-dir() {

  ".tomty/.cache"

}

our sub init () is export {

  mkdir ".tomty/.cache";
  mkdir ".tomty/env";

  my %conf = Hash.new;

  if "/home/{%*ENV<USER>}/tomty.yaml".IO ~~ :e {
    %conf = load-yaml(slurp "/home/{%*ENV<USER>}/tomty.yaml");
  }

  %conf;

}

sub tomty-usage () is export  {
  say 'usage: tomty $action|$options $thing'
}

sub tomty-help () is export  {
  say q:to/DOC/;
  usage:
    tomty $options $thing

  run all tests:
    tomty --all

  run tests in quiet mode:
    tomty -q

  run test:
    tomty $test

  remove test:
    tomty --remove $test

  print out test:
    tomty --cat $test

  print out test report:
    tomty --log $test

  set default ennvironment
    tomty --env-set $env

  actions:
    tomty --list              # list available tests
    tomty --completion        # install Bash completion
    tomty --env-set $env      # set current environment
    tomty --env-set           # show current environment
    tomty --env-list          # list available environments

  options:
    --env=$env  # run tests for the given environment
    --quiet,-q  # run tests in quiet mode

  DOC
}

# clean tomty internal data
# is useful as with time it might grow

sub tomty-clean ($dir) is export { 

  say "cleaning $dir/.cache ...";

  if "$dir/.cache/".IO ~~ :e {
    empty-directory "$dir/.cache"
  }

}

sub test-run ($dir,$test,%args?) is export {

  die "test $test not found" unless "$dir/$test.pl6".IO ~~ :e;

  my $conf-file;

  if %args<env> {

    $conf-file = %args<env> eq 'default' ?? "$dir/env/config.pl6" !! "$dir/env/config.{%args<env>}.pl6";

  } elsif "$dir/env/current".IO ~~ :e  && "$dir/env/current".IO.resolve.IO.basename {

    $conf-file = "$dir/env/current".IO.resolve;

  } elsif ( "$dir/env/config.pl6".IO ~~ :e ) {

    $conf-file = "$dir/env/config.pl6"

  }

  if $conf-file && $conf-file.IO ~~ :e {
    say "load configuration from $conf-file";
    set-config(EVALFILE $conf-file);
  }

  Sparrow6::Task::Repository::Api.new().index-update;

  EVALFILE "$dir/$test.pl6";

}

sub test-run-all ($dir,%args) is export {

  my $q-mode = %args<q-mode>;

  my $i;

  my $tests-cnt = 0;

  my $failures-cnt = 0;

  my $cnt = test-list($dir).elems;


  for test-list($dir) -> $s {

    my @macros;

    for "$dir/$s.pl6".IO.lines -> $l {

        if $l ~~ /^^ \s* '=begin tomty'/ ^fff^ $l ~~ /^^ \s* '=end tomty'/ {
            push @macros, $l;
        }
        
    }

    my %macros-state;

    if @macros {
      use MONKEY-SEE-NO-EVAL;
      %macros-state = EVAL @macros.join("\n");
    }

    $i++;

    if $q-mode {

      print "[$i/$cnt] / [$s] ....... ";

      if %args<skip> && %macros-state<tag> && so %args<skip> ∈ %macros-state<tag> {
        print " SKIP\n";
        next;
      }

    } else {

      say "[$s] ....... ";

    }


    my $proc = %args<env> ?? Proc::Async.new("tomty","--env", %args<env>,$s) !! Proc::Async.new("tomty",$s);

    my $fh = open "{reports-dir()}/$s.log", :w;

    my $start;

    react {

        whenever $proc.stdout.lines { # split input on \r\n, \n, and \r

          $fh.say($_);

          say $_ unless $q-mode;

        }

        whenever $proc.stderr { # chunks

          say $_ unless $q-mode;

        }

        whenever $proc.ready {
            $start = time;
            #say ‘PID: ’, $_ # Only in Rakudo 2018.04 and newer, otherwise Nil
        }

        whenever $proc.start {

            #say ‘Proc finished: exitcode=’, .exitcode, ‘ signal=’, .signal;

            my $exit-code = .exitcode;

            $tests-cnt++;

            if $exit-code != 0 {
              $failures-cnt++;
              print " {time - $start} sec. FAIL\n" if $q-mode;
            } else {
              print " {time - $start} sec. OK\n" if $q-mode;
            }

            $fh.close;

            done # gracefully jump from the react block

       }

    }

  }

  say "=========================================";

  if $failures-cnt >= 1 {
    say ")=: ({$tests-cnt - $failures-cnt}) tests passed / ($failures-cnt) failed";
    exit(1);
  } else {
    say "(=: ($tests-cnt) tests passed";
  }

}

sub test-log ($test) is export {

    if "{reports-dir()}/$test.log".IO ~~ :e {
      say slurp "{reports-dir()}/$test.log"
    } else {
      say "no log for test <$test> found"
    }

}

sub test-list ($dir) is export {

    my @list = Array.new;

    for dir($dir) -> $f {

      next unless "$f".IO ~~ :f;
      next unless $f ~~ /\.pl6$/;
      my $test-name = substr($f.basename,0,($f.basename.chars)-4);
      @list.push($test-name);

    }

    return @list.sort;

}

sub test-list-print ($dir) is export {

    say "[tests list]";

    my @list = test-list($dir);

    say join "\n", @list.sort;

}

sub test-remove ($dir,$test) is export {

  if "$dir/$test.pl6".IO ~~ :e {
    unlink "$dir/$test.pl6";
    say "test $test removed"
  } else {
    say "test $test not found"
  }

}

sub test-cat ($dir,$test,%args?) is export {

  if "$dir/$test.pl6".IO ~~ :e {
    say "[test $test]";
    my $i=0;
    
    for "$dir/$test.pl6".IO.lines -> $l {
      $i++;
      say %args<lines> ?? "[$i] $l" !! $l;
    }
  } else {
    say "test $test not found"
  }

}

sub test-edit ($dir,$test) is export {

    die "you should set EDITOR ENV to run editor" unless  %*ENV<EDITOR>;

    unless "$dir/$test.pl6".IO ~~ :e {
      my $confirm = prompt("$dir/$test.pl6 does not exit, do you want to create it? (type Y to confirm): ");
      return unless $confirm eq 'Y';
    }

    shell "{%*ENV<EDITOR>} $dir/$test.pl6";

}

sub environment-edit ($dir,$env) is export {

    die "you should set EDITOR ENV to run editor" unless  %*ENV<EDITOR>;

    my $conf-file = ( $env eq 'default' ) ?? "$dir/config.pl6" !! "$dir/config.{$env}.pl6";

    unless $conf-file.IO ~~ :e {
      my $confirm = prompt("$conf-file does not exit, do you want to create it? (type Y to confirm): ");
      return unless $confirm eq 'Y';
    }

    shell "{%*ENV<EDITOR>} $conf-file";

}

sub environment-list ($dir) is export {

    say "[environments list]";

    my @list = Array.new;

    my $current = "default";

    if "$dir/current".IO ~~ :e  && "$dir/current".IO.resolve.IO.basename {

      if "$dir/current".IO.resolve.IO.basename ~~ /config\.(.*)\.pl6/ {
        $current = "$0"
      }

    }

    for dir($dir) -> $f {

      next unless "$f".IO ~~ :f;
      next unless $f ~~ /\.pl6$/;

      if $f.basename ~~ /config\.(.*)\.pl6/ {

        @list.push("$0");

      } else {

        @list.push("default")

      }

    }

    for @list.sort -> $l {
      say $current eq $l ?? "$l *" !! $l
    };

}

sub environment-set ($dir,$env) is export {

  my $conf-file = $env eq 'default' ?? "$dir/config.pl6" !! "$dir/config.{$env}.pl6";

  die "environment $conf-file not found" unless $conf-file.IO ~~ :e;

  unlink "$dir/current" if "$dir/current".IO ~~ :e;

  symlink($conf-file,"$dir/current");

}

sub environment-show ($dir) is export {

  if "$dir/current".IO ~~ :e {

    my $current = "$dir/current".IO.resolve.IO.basename;

      if $current ~~ /config\.(.*)\.pl6/ {

        say "current environment: $0"

      } else {

        say "current environment: default"

      }

  } elsif "$dir/config.pl6".IO ~~ :e {

    say "default";

  } else {

    say "default environment is not set, create default configuration file (.tomty/env/config.pl6)
or use tom --set-env \$env to set default environments"
  }
  
}

sub environment-cat ($dir,$env,%args?) is export {

  my $conf-file;

  if $env eq "default" {
    $conf-file = "$dir/config.pl6"
  } else {
    $conf-file = "$dir/config.{$env}.pl6"
  }

  if "$conf-file".IO ~~ :e {
    say "[environment $env]";
    my $i=0;
    
    for "$conf-file".IO.lines -> $l {
      $i++;
      say %args<lines> ?? "[$i] $l" !! $l;
    }
  } else {
    say "environment $env not found"
  }

}


sub completion-install () is export {

  say "install completion.sh ...";

  my $fh = open '/home/' ~ %*ENV<USER> ~ '/.tomty_completion.sh' , :w;

  $fh.print(slurp %?RESOURCES{"completion.sh"}.Str);

  $fh.close;

  say "to activate completion say: source " ~ '/home/' ~ %*ENV<USER> ~ '/.tomty_completion.sh';

}

