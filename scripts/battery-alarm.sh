#!/usr/bin/env bash
# The loud loop itself. Started on-demand by battery-alarm-check.sh, killed by
# battery-alarm-check.sh (charger plugged in) or battery-alarm-dismiss.sh (snooze/keybind).

SOUND="/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

sound_loop() {
    while :; do
        paplay "$SOUND" 2>/dev/null
        sleep 5
    done
}

banner_loop() {
    while :; do
        cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
        hyprctl seterror "rgb(ff1744)" "CRITICAL BATTERY: ${cap}% — plug in now!"
        sleep 5
    done
}

# same banner Hyprland uses for config errors — persistent, updates in place,
# no restacking. Must clear it ourselves on exit, systemd killing this
# process won't touch it.
trap 'hyprctl seterror disable' EXIT TERM INT

sound_loop &
banner_loop &

action=$(notify-send -a "Battery Alarm" -u critical -A dismiss=Silence \
    "Critical Battery" "Plug in the charger, or click Silence for 5 minutes.")

[[ "$action" == "dismiss" ]] && "$SCRIPT_DIR/battery-alarm-dismiss.sh"

wait
