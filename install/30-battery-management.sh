#!/usr/bin/env bash

PROFILE_ON_AC="performance"
PROFILE_ON_BAT="power-saver"

####
[[ $EUID -ne 0 ]] && exec sudo -- "$0" "$@"

command -v upower &>/dev/null || {
    echo "⚠️ 'upower' command not found. Please install 'upower' package first."
    exit 1
}
command -v powerprofilesctl &>/dev/null || {
    echo "⚠️ 'powerprofilesctl' command not found. Please install 'power-profiles-daemon' package first."
    exit 1
}

if ! compgen -G "/sys/class/power_supply/BAT*" > /dev/null; then
    echo "⚠️ No batteries detected — skipping battery management setup."
    exit 0
fi

####
echo "🔋 Batteries detected, proceeding with setup..."

# --- install threshold script ---
cat >/usr/local/bin/set-battery-thresholds.sh <<'EOF'
#!/usr/bin/env bash
for bat_path in /sys/class/power_supply/BAT*; do
    bat_name=$(basename "$bat_path")

    [[ -w "$bat_path/charge_control_start_threshold" ]] || continue

    up_info=$(upower -i /org/freedesktop/UPower/devices/battery_${bat_name})
    design=$(echo "$up_info" | awk '/energy-full-design:/ {print $2}')
    current=$(echo "$up_info" | awk '/energy-full:/ && !/design/ {print $2}')
    [[ -z "$design" || -z "$current" ]] && continue
    wear=$(awk -v d="$design" -v c="$current" 'BEGIN { printf("%.0f", 100 - (c/d*100)) }')

    if   (( wear > 30 )); then START=85; STOP=95
    elif (( wear > 20 )); then START=80; STOP=90
    elif (( wear > 10 )); then START=75; STOP=85
    else START=70; STOP=80
    fi

    echo "[$bat_name] wear=$wear% → thresholds $START/$STOP"
    echo "$START" | tee "$bat_path/charge_control_start_threshold" >/dev/null
    echo "$STOP"  | tee "$bat_path/charge_control_end_threshold"  >/dev/null
done
EOF

chmod +x /usr/local/bin/set-battery-thresholds.sh
echo "✅ Installed /usr/local/bin/set-battery-thresholds.sh"

# --- install systemd service ---
cat >/etc/systemd/system/battery-thresholds.service <<'EOF'
[Unit]
Description=Set battery charge thresholds
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/set-battery-thresholds.sh

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now battery-thresholds.service >/dev/null 2>&1 || true
echo "✅ Enabled battery-thresholds.service"

# --- install power profile + auto threshold udev rule ---
cat >/etc/udev/rules.d/99-power-profile.rules <<EOF
ACTION=="change", SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="/usr/bin/powerprofilesctl set ${PROFILE_ON_AC}"
ACTION=="change", SUBSYSTEM=="power_supply", ATTR{online}=="1", RUN+="/usr/local/bin/set-battery-thresholds.sh"
ACTION=="change", SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="/usr/bin/powerprofilesctl set ${PROFILE_ON_BAT}"
ACTION=="change", SUBSYSTEM=="power_supply", ATTR{online}=="0", RUN+="/usr/local/bin/set-battery-thresholds.sh"
EOF

udevadm control --reload
udevadm trigger --subsystem-match=power_supply
echo "✅ Installed udev power profile + threshold update rules"

echo "🎉 Battery management setup complete."

