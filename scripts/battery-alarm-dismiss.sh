#!/usr/bin/env bash
# Shared dismiss action: used by the notify-send "Dismiss" button and the Hyprland keybind.
# Silences the alarm and stops battery-alarm-check.sh from re-triggering it for a while.

SNOOZE_SECONDS=300

mkdir -p "$HOME/.cache"
echo $(( $(date +%s) + SNOOZE_SECONDS )) > "$HOME/.cache/battery-alarm-snoozed-until"
systemctl --user stop battery-alarm.service
