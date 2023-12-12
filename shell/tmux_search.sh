#!/bin/bash

# Usage: t <optional zoxide-like dir, relative or absolute path>
# If no argument is given, a combination of existing sessions and a zoxide query will be displayed in a FZF

# Parse optional argument
if [ "$1" ]; then
  # Argument is given
  eval "$(zoxide init bash)"
  RESULT=$(z $@ && pwd)
else
  # No argument is given. Use FZF
  RESULT=$((tmux list-sessions -F "#{session_name}: #{session_windows} window(s)\
#{?session_grouped, (group ,}#{session_group}#{?session_grouped,),}\
#{?session_attached, (attached),}"; zoxide query -l) | $HOME/.fzf/shell/fzfp )
  if [ -z "$RESULT" ]; then
    exit 0
  fi
fi

# Get or create session
if [[ $RESULT == *":"* ]]; then
  # RESULT comes from list-sessions
  SESSION=$(echo $RESULT | awk '{print $1}')
  SESSION=${SESSION//:/}
else
  # RESULT is a path
  SESSION=$(basename $RESULT | tr . _)
  if ! tmux has-session -t=$SESSION 2> /dev/null; then
    tmux new-session -d -s $SESSION -c $RESULT
  fi
fi

# Attach to session
if [ -z "$TMUX" ]; then
  tmux attach -t $SESSION
else
  tmux switch-client -t $SESSION
fi