#!/usr/bin/env bash
# amux task <name> — simple task session in current dir
source "$(dirname "$(realpath "$0")")/../lib.sh"

TASK="$1"
if [ -z "$TASK" ]; then echo "usage: amux task <name>"; exit 1; fi

DIR="$(pwd)"

tmux has-session -t "$TASK" 2>/dev/null && tmux_goto "$TASK" && exit

tmux new-session -d -s "$TASK" -c "$DIR" -n nvim

tmux send-keys -t "$TASK:nvim" "nvim ." Enter
tmux split-window -h -t "$TASK:nvim" -c "$DIR"
tmux send-keys -t "$TASK:nvim" "claude" Enter

tmux new-window -t "$TASK" -n bash -c "$DIR"

tmux select-window -t "$TASK:nvim"
tmux select-pane -t "$TASK:nvim.1"
tmux_goto "$TASK"
