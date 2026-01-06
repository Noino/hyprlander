#!/usr/bin/env bash

keepassxc &
pid=$!

while ! hyprctl clients | grep -E "KeePassXC"; do sleep 0.1; done
hyprctl dispatch movetoworkspacesilent special:keepass,'initialclass:org.keepassxc.KeePassXC'
