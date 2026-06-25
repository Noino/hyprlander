#!/usr/bin/env bash
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../lib.sh"

load() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    read -rp "session name: " name
    [[ -z "$name" ]] && return 0
  fi
  tmux has-session -t "$name" 2>/dev/null && tmux_goto "$name" && return
  tmux new-session -d -s "$name"
  tmux set-environment -t "$name" AMUX_TEMPLATE "_basic"
  tmux_goto "$name"
}

unload() {
  tmux kill-session -t "$1" 2>/dev/null
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && load "$@"
