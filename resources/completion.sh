#/usr/bin/env bash

tomty_completions()
{
  
  cur_word="${COMP_WORDS[COMP_CWORD]:-UNKNOWN}"
  prev_word=${COMP_WORDS[COMP_CWORD-1]:-UNKNOWN}

  type=$(perl6 -MTomty::Completion -ecomplete $( IFS=$'\t'; echo "${COMP_WORDS[*]}" ) ${prev_word} ${cur_word} tp)
  list=$(perl6 -MTomty::Completion -ecomplete $( IFS=$'\t'; echo "${COMP_WORDS[*]}" ) ${prev_word} ${cur_word} ls)



  if test "${type}" = "test_list2"; then
    COMPREPLY=( $( compgen -W "${list}"))
  fi

  if test "${type}" = "test_list"; then
    COMPREPLY=( $( compgen -W "${list}" -- ${COMP_WORDS[COMP_CWORD]}  ))
  fi

  if test "${type}" = "env_list2"; then
    COMPREPLY=( $( compgen -W "${list}" ))
  fi

  if test "${type}" = "env_list"; then
    COMPREPLY=( $( compgen -W "${list}" -- ${COMP_WORDS[COMP_CWORD]}  ))
  fi


  if test "${type}" = "opt_list"; then
    COMPREPLY=( $( compgen -W "${list}" -- ${COMP_WORDS[COMP_CWORD]}  ))
  fi


}

complete -F tomty_completions tomty
