#!/usr/bin/env bash
AMUX_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

tmux_goto() {
  [[ -n "$TMUX" ]] && tmux switch-client -t "$1" || tmux attach -t "$1"
}
