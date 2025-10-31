#!/usr/bin/env bash

# if has args, run only specified modules
# otherwise run all modules in the install folder sorted alphabetically
if [ "$#" -gt 0 ]; then
    for module in "$@"; do
        if [ -f "install/$module.sh" ]; then
            echo "Running install/$module.sh"
            bash "install/$module.sh"
        else
            echo "Module install/$module.sh not found!"
        fi
    done
else
    for script in $(ls install/*.sh | sort); do
        echo "Running $script"
        bash "$script"
    done
fi
