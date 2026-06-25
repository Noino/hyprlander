#!/usr/bin/env bash
# amux task <name> — simple task session in current dir
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../lib.sh"

load() {
  TASK="$1"
  if [ -z "$TASK" ]; then echo "usage: amux task <task>"; return 1; fi

  local DIR; DIR="$(pwd)"

  tmux has-session -t "$TASK" 2>/dev/null && tmux_goto "$TASK" && return

  tmux new-session -d -s "$TASK" -c "$DIR" -n nvim
  tmux set-environment -t "$TASK" AMUX_TEMPLATE "_task"

  tmux send-keys -t "$TASK:nvim" "nvim ." Enter
  tmux split-window -h -t "$TASK:nvim" -c "$DIR"
  tmux send-keys -t "$TASK:nvim" "claude --resume 2>/dev/null || claude" Enter

  tmux new-window -t "$TASK" -n bash -c "$DIR"

  tmux select-window -t "$TASK:nvim"
  tmux select-pane -t "$TASK:nvim.1"
  tmux_goto "$TASK"
}

unload() {
  TASK="$1"
  tmux kill-session -t "$TASK" 2>/dev/null
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && load "$@"
