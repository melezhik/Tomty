#!perl6

use v6;

unit module Tomty:ver<0.0.17>;

use Sparrow6::Task::Repository;

use Sparrow6::DSL;

use YAMLish;

use File::Directory::Tree;

use Colorizable;

# tomty cli initializer

sub reports-dir() {

  ".tomty/.cache"

}

our sub check-if-init ( $dir ) is export {

  if ! ($dir.IO ~~ :d) {
        say "tomty is not initialized, run tomty --init";
        exit(1);
  }

}

our sub init ($dir) is export {

  mkdir $dir;

}

our sub load-conf () is export {

  my %conf = Hash.new;

  if $*DISTRO.is-win {
    if "{%*ENV<HOMEDRIVE>}{%*ENV<HOMEPATH>}/tomty.yaml".IO ~~ :e {
      %conf = load-yaml(slurp "{%*ENV<HOMEDRIVE>}{%*ENV<HOMEPATH>}/tomty.yaml");
    }
  } else {  
    if "{%*ENV<HOME>}/tomty.yaml".IO ~~ :e {
      %conf = load-yaml(slurp "{%*ENV<HOME>}/tomty.yaml");
    }
  }
  %conf;

}

our sub read-profile ($dir, $profile, %args?) is export {

  my %profile-data;

  if "$dir/profile".IO ~~ :f {

      say "read profiles from $dir/profile" if %args<verbose>;

      my %profiles = EVALFILE "$dir/profile";
      if %profiles{$profile}:exists {
        say "profile <$profile> found" if %args<verbose>;
        %profile-data = %profiles{$profile};
        if %*ENV<TOMTY_DEBUG> {
          say "<$profile> profile: ", %profile-data.perl;
        }  
      } else {
        say "[WARN] profile <$profile> not found" 
      }
  }

  return %profile-data;

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

  run only tests:
    tomty --only=dev

  run all tests, excluding:
    tomty --skip=prod

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
    tomty --tags              # list available tags

  options:
    --env=$env  # run tests for the given environment

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

  die "test $test not found" unless "$dir/$test.raku".IO ~~ :e;

  mkdir "$dir/.cache";

  my $conf-file;

  my $current-env = current-env("{$dir}/env");

  if %args<env> {

    $conf-file = %args<env> eq 'default' ?? "$dir/env/config.raku" !! "$dir/env/config.{%args<env>}.raku";

  } elsif $current-env eq 'default' &&  "$dir/env/config.raku".IO ~~ :e {

    $conf-file =  "$dir/env/config.raku";

  } elsif "$dir/env/config.{$current-env}.raku".IO ~~ :e  {

    $conf-file = "$dir/env/config.{$current-env}.raku";

  }

  if $conf-file && $conf-file.IO ~~ :e {
    my $message =  "load configuration from $conf-file" but Colorizable;
    say %args<color> ?? "{$message.colorize(:fg(cyan), :mo(bold))}" !! $message;
    set-config(EVALFILE $conf-file);
  }

  Sparrow6::Task::Repository::Api.new().index-update;

  EVALFILE "$dir/$test.raku";

}

sub array-include-tag ($arr, Str $tag) {
  my $status = True;
  for $tag.split(/'+'/) -> $t {
    unless $arr<> (cont) $t {
      $status = False;
      last;
    }
  }

  return $status;
}

sub filter-tests ($dir, %args) {

  my @tests;

  my $i;

  for test-list($dir) -> $s {

    my @macros;

    for "$dir/$s.raku".IO.lines -> $l {

        if $l ~~ /^^ \s* '=begin tomty'/ ^fff^ $l ~~ /^^ \s* '=end tomty'/ {
            push @macros, $l;
        }
        
    }

    my %macros-state;

    if @macros {
      use MONKEY-SEE-NO-EVAL;
      %macros-state = EVAL @macros.join("\n");

      if %*ENV<TOMTY_DEBUG> {
        say "\%macros-state: ", %macros-state.perl;
      }
  
    }

    my $is-included = True;
    my $skip = True;

    $i++;

    if %args<only> {

      for %args<only>.split(/','/).map({.subst(/\s/,"",:g)}) -> $t {
        $is-included = array-include-tag(%macros-state<tag>,$t);
        last if $is-included; # only check first occuarance
      }
      
    }

    $skip = ! $is-included;

    if $is-included and %args<skip> {

      for %args<skip>.split(/','/).map({.subst(/\s/,"",:g)}) -> $t {
        $is-included = array-include-tag(%macros-state<tag>,$t);
        last if $is-included; # only check first occuarance
      }
      $skip = True if $is-included;  
    }

    push @tests, %( skip => $skip, test => $s, tags => %macros-state<tag> );

  } # next test

  return @tests;

}

sub tags-print ($dir, %args) is export {

  my @t = filter-tests($dir, %()).grep({.<skip> == False});

  my %tags;

  for @t -> $t {

    for $t<tags><> -> $tg {
      if $tg === Any {
        %tags{"untagged"}++
      } else {
        %tags{$tg}++
      }
    }

  }

  my $i = 0;

  for %tags.keys.sort -> $tg {

    my $tg-s = $tg but Colorizable;
    my $tg-cnt = %tags{$tg} but Colorizable;

    if %args<color> {
      say $tg-s.colorize(:fg(green),:mo(bold)), " ", $tg-cnt.colorize(:fg(cyan),:mo(bold));
    } else {
      say $tg-s, " ", $tg-cnt;
    }

    $i++;

  }

  say "==========";
  say "[$i] tags";

}

sub list-tests-with-tags ($dir,%args) {

  my @t = filter-tests($dir, %args).grep({.<skip> == False});

  my $i = 0;

  for @t -> $t {

    my $s = $t<test> but Colorizable;
    my $tags-str = "{$t<tags>.perl}" but Colorizable;
    $i++;

    if %args<color> {
      say $s.colorize(:fg(green),:mo(bold)), " ", $t<tags> ??  $tags-str.colorize(:fg(cyan),:mo(bold)) !! "";
    } else {
      say $s, " ", $t<tags> ?? $tags-str !! "";
    }

  }

  say "==========";
  say "[$i] tests";

}

sub test-run-all ($dir,%args) is export {

  return list-tests-with-tags($dir,%args) if %args<tags>;

  my $verbose-mode = %args<verbose-mode>;

  my $i;

  my $tests-cnt = 0;

  my $failures-cnt = 0;

  mkdir "$dir/.cache";

  my $cnt = test-list($dir).elems;

  my $start-all = time;

  unlink "{reports-dir()}/.failures.log" if "{reports-dir()}/.failures.log".IO ~~ :e;

  for filter-tests($dir, %args) -> $t {

    $i++;

    my $s = $t<test>;

    my $skip = $t<skip>;

    if ! $verbose-mode {

      if $skip {
        if !%args<only> {
          my $message  = "[$i/$cnt] / [$s] ....... SKIP" but Colorizable;
          say %args<color> ?? "{$message.colorize(:fg(yellow),:mo(bold))}" !! $message;
        }
        next;
      } else {
        my $message = "[$i/$cnt] / [$s] ....... " but Colorizable;
        print %args<color> ?? "{$message.colorize(:fg(green),:mo(bold))}" !! $message;
      }


    } else {

      if $skip {
        my $message = "[$s] ....... SKIP" but Colorizable;
        say %args<color> ?? "{$message.colorize(:fg(yellow),:mo(bold))}" !! $message;
        next;
      } else {
        my $message = "[$s] ....... " but Colorizable;
        say %args<color> ?? "{$message.colorize(:fg(green),:mo(bold))}" !! $message;
      }

    }

    my @cmd = $*DISTRO.is-win ?? ("cmd.exe","/c","tomty") !! ("tomty");

    ($*OUT,$*ERR).map: {.out-buffer = 0};

    my @tomty-args = Array.new;

    @tomty-args.push("--env={%args<env>}") if %args<env>;

    @tomty-args.push("--color") if %args<color>;

    my $proc = Proc::Async.new(@cmd,@tomty-args,$s);

    my $fh = open "{reports-dir()}/$s.log", :w;

    my $start;

    react {

        whenever $proc.stdout.lines { # split input on \r\n, \n, and \r

          $fh.say($_);

          say $_ if $verbose-mode;

        }

        whenever $proc.stderr { # chunks

          $fh.say($_);

          say $_ if $verbose-mode;

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
              $fh.close;
              my $message = " {time - $start} sec. FAIL" but Colorizable;
              if ! $verbose-mode {
                say %args<color> ?? $message.colorize(:fg(red),:mo(bold)) !! $message;
              }
              my $fh1 = open "{reports-dir()}/.failures.log", :a;
              $fh1.say("[$s]");
              $fh1.say("{reports-dir()}/$s.log".IO.slurp);
              $fh1.close;
           } else {
              my $message = " {time - $start} sec. OK" but Colorizable;
              if ! $verbose-mode {
                say %args<color> ?? $message.colorize(:fg(green),:mo(bold)) !! $message;
              }
              $fh.close;
            }


            done # gracefully jump from the react block

       }

    }

  } # next test

  say "=========================================";

  if $failures-cnt >= 1 {
    my $message =  ")=: / [$i] tests in {time - $start-all} sec / ({$tests-cnt - $failures-cnt}) tests passed / ($failures-cnt) failed"
      but Colorizable;
      say %args<color> ?? $message.colorize(:fg(red),:mo(bold)) !! $message;
    if ! $verbose-mode && %args<show-failed> {
      say "[Failed tests]";
      say "{reports-dir()}/.failures.log".IO.slurp
    }
    exit(1);
  } else {
    my $message = "(=: / [$i] tests in {time - $start-all} sec / ($tests-cnt) tests passed" 
      but Colorizable;
      say %args<color> ?? $message.colorize(:fg(green),:mo(bold)) !! $message;
  }

}

sub test-log ($test, %env = %() ) is export {

    if "{reports-dir()}/$test.log".IO ~~ :e {
      if $*DISTRO.is-win {
        say "{reports-dir()}/$test.log".IO.slurp
      } else {
        shell %env<color> ??  "less -r {reports-dir()}/$test.log" !! "less {reports-dir()}/$test.log";
      }
      
    } else {
      say "no log for test <$test> found"
    }

}

sub test-list ($dir) is export {

    my @list = Array.new;

    for dir($dir) -> $f {

      next unless "$f".IO ~~ :f;
      next unless $f ~~ /\.raku$/;
      my $test-name = substr($f.basename,0,($f.basename.chars)-5);
      @list.push($test-name);

    }

    return @list.sort;

}

sub test-list-print ($dir, %args?) is export {

    my @list = test-list($dir);
    my $current-env = current-env("$dir/env");

    say "[{$current-env}@tests]" unless %args<noheader>;
    say join "\n", @list.sort;

}

sub test-remove ($dir,$test) is export {

  if "$dir/$test.raku".IO ~~ :e {
    unlink "$dir/$test.raku";
    say "test $test removed"
  } else {
    say "test $test not found"
  }

}

sub test-cat ($dir,$test,%args?) is export {

  if "$dir/$test.raku".IO ~~ :e {
    say "[test $test]";
    my $i=0;
    
    for "$dir/$test.raku".IO.lines -> $l {
      $i++;
      say %args<lines> ?? "[$i] $l" !! $l;
    }
  } else {
    say "test $test not found"
  }

}

sub test-edit ($dir,$test) is export {

    die "you should set EDITOR ENV to run editor" unless  %*ENV<EDITOR>;

    unless "$dir/$test.raku".IO ~~ :e {
      my $confirm = prompt("$dir/$test.raku does not exit, do you want to create it? (type Y to confirm): ");
      return unless $confirm eq 'Y';
    }

    shell "{%*ENV<EDITOR>} $dir/$test.raku";

}

sub current-env ($dir) {

  my $current;

  if "$dir/current".IO ~~ :e {
    $current = slurp "$dir/current";
  }

  return $current || "default"

}

sub environment-edit ($dir,$env) is export {

    die "you should set EDITOR ENV to run editor" unless  %*ENV<EDITOR>;

    mkdir $dir;

    my $conf-file = ( $env eq 'default' ) ?? "$dir/config.raku" !! "$dir/config.{$env}.raku";

    unless $conf-file.IO ~~ :e {
      my $confirm = prompt("$conf-file does not exit, do you want to create it? (type Y to confirm): ");
      return unless $confirm eq 'Y';
    }

    shell "{%*ENV<EDITOR>} $conf-file";

}

sub environment-list ($dir) is export {

    say "[environments list]";

    my @list = Array.new;

    mkdir $dir;

    my $current = current-env($dir);

    for dir($dir) -> $f {

      next unless "$f".IO ~~ :f;
      next unless $f ~~ /\.raku$/;

      if $f.basename ~~ /config\.(.*)\.raku/ {

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

  # next lines removes "current" symlink if it exist
  # we don't need this for tomty projects
  # generated by the latest version of Tomty
  # where environment manager no longer
  # uses symlinks


  unlink "$dir/current" if "$dir/current".IO ~~ :e;

  mkdir $dir;

  spurt "$dir/current", $env;

}

sub environment-show ($dir) is export {

  if "$dir/current".IO ~~ :f {
    say "current environment: ",slurp("$dir/current")
  } elsif ( "$dir/config.raku".IO ~~ :f) {
    say "current environment: default";
  } else {
    say "default environment is not set, create default configuration file (.tomty/env/config.raku)
or use tomty --set-env \$env to set default environments"
  }
}

sub environment-cat ($dir,$env,%args?) is export {

  my $conf-file;

  if $env eq "default" {
    $conf-file = "$dir/config.raku"
  } else {
    $conf-file = "$dir/config.{$env}.raku"
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

  my $fh = open %*ENV<HOME> ~ '/.tomty_completion.sh' , :w;

  $fh.print(slurp %?RESOURCES{"completion.sh"}.Str);

  $fh.close;

  say "to activate completion say: source " ~ %*ENV<HOME> ~ '/.tomty_completion.sh';

}

