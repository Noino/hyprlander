#!/usr/bin/env bash
# Shared helpers for reading every battery in /sys/class/power_supply.
# Sourced by battery-alarm-check.sh and battery-alarm.sh; running it directly
# prints the combined capacity, which is handy for debugging.

# Overridable mainly so the helpers can be tested against a fake sysfs tree.
BATTERY_PATH="${BATTERY_PATH:-/sys/class/power_supply}"

# Prints the combined charge of all batteries as a percentage (0-100).
# Packs are weighted by their current full capacity, so differently sized or
# worn batteries count proportionally. Returns non-zero if there is no battery.
battery_total_capacity() {
    local bat value
    local count=0 capacity_sum=0
    local energy_now=0 energy_full=0 have_energy=1
    local charge_now=0 charge_full=0 have_charge=1

    for bat in "$BATTERY_PATH"/BAT*; do
        [[ -r "$bat/capacity" ]] || continue

        count=$(( count + 1 ))
        value=$(<"$bat/capacity")
        capacity_sum=$(( capacity_sum + value ))

        if [[ -r "$bat/energy_now" && -r "$bat/energy_full" ]]; then
            value=$(<"$bat/energy_full")
            if (( value > 0 )); then
                energy_now=$(( energy_now + $(<"$bat/energy_now") ))
                energy_full=$(( energy_full + value ))
            else
                have_energy=0
            fi
        else
            have_energy=0
        fi

        if [[ -r "$bat/charge_now" && -r "$bat/charge_full" ]]; then
            value=$(<"$bat/charge_full")
            if (( value > 0 )); then
                charge_now=$(( charge_now + $(<"$bat/charge_now") ))
                charge_full=$(( charge_full + value ))
            else
                have_charge=0
            fi
        else
            have_charge=0
        fi
    done

    (( count == 0 )) && return 1

    if (( have_energy )); then
        echo $(( energy_now * 100 / energy_full ))
    elif (( have_charge )); then
        echo $(( charge_now * 100 / charge_full ))
    else
        # Last resort: unweighted average of the reported capacities.
        echo $(( capacity_sum / count ))
    fi
}

# Succeeds if at least one battery is currently discharging (i.e. on battery).
battery_is_discharging() {
    local bat
    for bat in "$BATTERY_PATH"/BAT*; do
        [[ -r "$bat/status" ]] || continue
        [[ "$(<"$bat/status")" == "Discharging" ]] && return 0
    done
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    battery_total_capacity
fi
