#!/usr/bin/env bash
# Started every 20s by battery-alarm-check.timer.
# Starts/stops the loud battery-alarm.service based on current battery state.
# All batteries are combined (see battery-status.sh), so dual-battery laptops
# that discharge one pack at a time only alarm when the total charge is low.

THRESHOLD=25
SNOOZE_FILE="$HOME/.cache/battery-alarm-snoozed-until"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# shellcheck source=battery-status.sh
source "$SCRIPT_DIR/battery-status.sh"

capacity=$(battery_total_capacity) || exit 0

stop_alarm() {
    systemctl --user is-active --quiet battery-alarm.service && systemctl --user stop battery-alarm.service
}

# Nothing discharging means we are on AC or fully charged.
if ! battery_is_discharging; then
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
