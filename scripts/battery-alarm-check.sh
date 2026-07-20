#!/usr/bin/env bash
# Started every 20s by battery-alarm-check.timer.
# Starts/stops the loud battery-alarm.service based on current battery state.

THRESHOLD=25
SNOOZE_FILE="$HOME/.cache/battery-alarm-snoozed-until"

status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
capacity=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)

[[ -z "$capacity" || -z "$status" ]] && exit 0

stop_alarm() {
    systemctl --user is-active --quiet battery-alarm.service && systemctl --user stop battery-alarm.service
}

if [[ "$status" != "Discharging" ]]; then
    rm -f "$SNOOZE_FILE"
    stop_alarm
    exit 0
fi

if (( capacity > THRESHOLD )); then
    stop_alarm
    exit 0
fi

if [[ -f "$SNOOZE_FILE" ]] && (( $(date +%s) < $(cat "$SNOOZE_FILE") )); then
    exit 0
fi

systemctl --user is-active --quiet battery-alarm.service || systemctl --user start battery-alarm.service
