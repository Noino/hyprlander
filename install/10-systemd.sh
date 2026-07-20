#!/usr/bin/env bash

# enable user services that run under graphical-session.target (uwsm)
systemctl --user daemon-reload
systemctl --user enable \
    dms.service \
    hypridle.service \
    hyprpolkitagent.service \
    cliphist.service \
    cliphist-images.service

if compgen -G "/sys/class/power_supply/BAT*" > /dev/null; then
    systemctl --user enable --now battery-alarm-check.timer
else
    echo "⚠️ No batteries detected — skipping battery-alarm-check.timer."
fi
