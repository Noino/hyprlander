#!/usr/bin/env bash

kill -9 $(hyprctl activewindow | grep -o 'pid: [0-9]*' | cut -d' ' -f2)

