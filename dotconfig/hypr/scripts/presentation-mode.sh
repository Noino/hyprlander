#!/usr/bin/env bash
# presentation-mode [on|off|toggle|status] — default: toggle
#
# Swaps the shell prompt to a date+time form and the wallpaper to something neutral.
# The prompt half works by state file only: bash_configs re-reads it every prompt via
# PROMPT_COMMAND, so already-open shells switch without being restarted.
set -u

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
FLAG="$STATE_DIR/presentation-mode"
SAVED_WALL="$STATE_DIR/presentation-mode.wallpaper"
PRESENT_WALL="${PRESENTATION_WALLPAPER:-$HOME/Pictures/bg/presentation.png}"

notify() { command -v notify-send >/dev/null 2>&1 && notify-send -a "presentation mode" "$1" "${2:-}" 2>/dev/null; }

on() {
  mkdir -p "$STATE_DIR"
  # remember the real wallpaper before overwriting, so off() restores exactly what was
  # there rather than a hardcoded default
  local current
  current="$(dms ipc call wallpaper get 2>/dev/null)"
  [[ -n "$current" && "$current" != "$PRESENT_WALL" ]] && printf '%s\n' "$current" > "$SAVED_WALL"

  if [[ -f "$PRESENT_WALL" ]]; then
    dms ipc call wallpaper set "$PRESENT_WALL" >/dev/null 2>&1
  else
    notify "wallpaper not found" "$PRESENT_WALL — prompt still switched"
  fi

  : > "$FLAG"
  notify "on" "prompt + wallpaper switched"
}

off() {
  local prev=""
  [[ -f "$SAVED_WALL" ]] && prev="$(cat "$SAVED_WALL")"
  if [[ -n "$prev" && -f "$prev" ]]; then
    dms ipc call wallpaper set "$prev" >/dev/null 2>&1
  fi
  rm -f "$FLAG" "$SAVED_WALL"
  notify "off" "restored"
}

case "${1:-toggle}" in
  on)     on ;;
  off)    off ;;
  status) [[ -e "$FLAG" ]] && echo on || echo off ;;
  toggle) [[ -e "$FLAG" ]] && off || on ;;
  *)      echo "usage: presentation-mode [on|off|toggle|status]" >&2; exit 1 ;;
esac
