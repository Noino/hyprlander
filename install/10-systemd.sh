#!/usr/bin/env bash

# enable user services that run under graphical-session.target (uwsm)
systemctl --user daemon-reload
systemctl --user enable \
    dms.service \
    hypridle.service \
    hyprpolkitagent.service \
    cliphist.service \
    cliphist-images.service
