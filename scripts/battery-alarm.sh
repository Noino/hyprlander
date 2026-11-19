#!/usr/bin/env bash
# The loud loop itself. Started on-demand by battery-alarm-check.sh, killed by
# battery-alarm-check.sh (charger plugged in) or battery-alarm-dismiss.sh (snooze/keybind).

SOUND="/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# shellcheck source=battery-status.sh
source "$SCRIPT_DIR/battery-status.sh"

sound_loop() {
    while :; do
        paplay "$SOUND" 2>/dev/null
        sleep 5
    done
}

banner_loop() {
    while :; do
        cap=$(battery_total_capacity) || cap="?"
        hyprctl seterror "rgb(ff1744)" "CRITICAL BATTERY: ${cap}% — plug in now!"
        sleep 5
    done
}

# same banner Hyprland uses for config errors — persistent, updates in place,
# no restacking. Must clear it ourselves on exit, systemd killing this
# process won't touch it. Stop the writer loops first: if the banner loop is
# still alive it can re-create the bar right after we clear it.
cleanup() {
    trap - EXIT TERM INT

    local pids
    pids=$(jobs -p)
    if [[ -n "$pids" ]]; then
        kill $pids 2>/dev/null
        wait $pids 2>/dev/null
    fi

    hyprctl seterror disable

    # A banner write can still be in flight when its loop is killed. Give it a
    # moment to finish, then clear again so it cannot leave the bar behind.
    sleep 0.2
    hyprctl seterror disable
}

trap cleanup EXIT
trap 'exit 143' TERM
trap 'exit 130' INT

sound_loop &
banner_loop &

cap=$(battery_total_capacity) || cap="?"
action=$(notify-send -a "Battery Alarm" -u critical -A dismiss=Silence \
    "Critical Battery (${cap}%)" "Plug in the charger, or click Silence for 5 minutes.")

[[ "$action" == "dismiss" ]] && "$SCRIPT_DIR/battery-alarm-dismiss.sh"

wait
