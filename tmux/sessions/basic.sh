#!/usr/bin/env bash
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../lib.sh"

load() {
  local name="${1:-}"
  if [[ -z "$name" ]]; then
    name=$(tmux new-session -d -P -c "$HOME" -F '#{session_name}')
    tmux set-environment -t "$name:" AMUX_TEMPLATE "basic"
    amux_state_set "$name" template "basic"
    amux_state_set "$name" dir "$HOME"
    amux_claim "$name" "${AMUX_ROLE:-misc}"
    tmux_goto "$name"
    return
  fi
  tmux has-session -t "$name:" 2>/dev/null && tmux_goto "$name" && return
  tmux new-session -d -s "$name" -c "$HOME"
  tmux set-environment -t "$name:" AMUX_TEMPLATE "basic"
  amux_state_set "$name" template "basic"
  amux_state_set "$name" dir "$HOME"
  amux_claim "$name" "${AMUX_ROLE:-misc}"
  tmux_goto "$name"
}

unload() {
  kill_session_safely "$1"
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && load "$@"
