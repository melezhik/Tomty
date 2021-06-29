use v6;

# this module is not meant for direct usage
# it's used for Bash completion
# perl -MTomty::Completion -ecomplete @args
# see also resources/completion.sh


unit module Tomty::Completion;

require Tomty;

::("Tomty::" ~ '&init')("$*CWD");

sub complete () is export {

  my @args = @*ARGS;

  my $mode = @args[*-1]:delete;
  my $current-word = @args[*-1]:delete;
  my $prev-word = @args[*-1]:delete;


  my $args = @args.join(" ");

    if %*ENV<TOMTY_COMPLETE_DEBUG> {

      my $fh = open "/tmp/complete.txt", :a;
      $fh.say("current word: <$current-word>");
      $fh.say("prev word: <$prev-word>");
      $fh.say("history: <$args>");
      $fh.close;

    }



  if $prev-word eq '--help' {
    return
  }


  # tests

  if $prev-word eq 'tomty' and $current-word ~~ /^ '--cat' | '--edit' | '--remove'  /  {

    my $list = test-list("{$*CWD}/.tomty",2);

    print $mode eq 'tp' ?? 'test_list' !! $list;

    return

  }

  if $prev-word ~~ /^ '--cat' | '--edit' | '--remove'  / or $current-word ~~ /^ '--cat' | '--edit'  | '--remove'  / {

    my $list = test-list("{$*CWD}/.tomty");

    print $mode eq 'tp' ?? 'test_list' !! $list;

    return

  }

  # environments

  if $prev-word eq 'tomty' and $current-word ~~ /^ '--env-set' | '--env-edit' | '--env-cat' /  {

    my $list = environment-list("{$*CWD}/.tomty/env",2);

    print $mode eq 'tp' ?? 'env_list' !! $list;

    return

  }

  if $prev-word ~~ /^ '--env-set' | '--env-edit' | '--env-cat' / or $current-word ~~ /^ '--env-set' | '--env-edit' | '--env-cat' / {

    my $list = environment-list("{$*CWD}/.tomty/env");

    print $mode eq 'tp' ?? 'env_list' !! $list;

    return

  }


  # tests

  if $prev-word eq 'tomty' && $current-word eq "UNKNOWN" {

    my $list = test-list("{$*CWD}/.tomty/");

    print $mode eq 'tp' ?? 'test_list2' !! $list;

    return;

  }

  # options

  if $current-word ~~ /^ '-' ** 1..2 / {

    my $list = options-list();
    
    print $mode eq 'tp' ?? 'opt_list' !! $list;
   
    return;

  }


  # tests

  my $list = test-list("{$*CWD}/.tomty/");

  print $mode eq 'tp' ?? 'test_list' !! $list;

  return;

}



sub options-list {

  my $list =  "--verbose --completion --clean --color --help --log --list --all -a --show-failed --profile --tags --skip --only --remove --cat --lines --edit --env-cat --env-set --env-edit --env-list --noheader";

    if %*ENV<TOMTY_COMPLETE_DEBUG> {

      my $fh = open "/tmp/complete.txt", :a;
      $fh.say("options list triggered");
      $fh.say($list);
      $fh.close;
    }

    return $list;
}

sub test-list ($dir, $type = 1) {

    my @list = Array.new;

    for dir($dir) -> $f {

      next unless "$f".IO ~~ :f;
      next unless $f ~~ /\.pl6$/;
      my $test-name = substr($f.basename,0,($f.basename.chars)-4);
      @list.push($test-name);

    }

    if %*ENV<TOMTY_COMPLETE_DEBUG> {

      my $fh = open "/tmp/complete.txt", :a;
      $fh.say("test list triggered, type: $type");
      $fh.say("{join " ", @list.sort}");
      $fh.close;

    }

    join " ", @list.sort;

}

sub environment-list ($dir, $type = 1 )  {


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

    if %*ENV<TOMTY_COMPLETE_DEBUG> {

      my $fh = open "/tmp/complete.txt", :a;
      $fh.say("environments list triggered, type: $type");
      $fh.say("{join " ", @list.sort}");
      $fh.close;

    }

    join " ", @list.sort;

}

