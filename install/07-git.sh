#!/usr/bin/env bash

git config --global user.name "Noino"
git config --global user.email "willewendell@gmail.com"

git config --global pull.rebase true
git config --global submodule.recurse true

git config --global alias.co '!~/.config/.scripts/git-checkout.sh'
