#!/usr/bin/env bash

# enable user services that run under graphical-session.target (uwsm)
systemctl --user daemon-reload
systemctl --user enable \
    dms.service \
    hypridle.service \
    hyprpolkitagent.service \
    cliphist.service \
    cliphist-images.service

# The repo doubles as ~/.config/systemd when installed, so systemd creates
# enablement symlinks inside it. Rewrite the repo-local ones as relative links
# so they keep working under any $HOME instead of hardcoding /home/<user>.
mkdir -p "$HOME/.config/systemd/user/graphical-session.target.wants" \
         "$HOME/.config/systemd/user/shutdown.target.wants" \
         "$HOME/.config/systemd/user/timers.target.wants"
ln -sfn ../cliphist-images.service "$HOME/.config/systemd/user/graphical-session.target.wants/cliphist-images.service"
ln -sfn ../tmux-save.service "$HOME/.config/systemd/user/shutdown.target.wants/tmux-save.service"

if compgen -G "/sys/class/power_supply/BAT*" > /dev/null; then
    systemctl --user enable --now battery-alarm-check.timer
    ln -sfn ../battery-alarm-check.timer "$HOME/.config/systemd/user/timers.target.wants/battery-alarm-check.timer"
else
    echo "⚠️ No batteries detected — skipping battery-alarm-check.timer."
fi
