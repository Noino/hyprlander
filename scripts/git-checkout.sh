#!/usr/bin/env bash

[[ -n "$(git status 2>/dev/null)" ]] && {
    [[ $# -gt 0 ]] && { git checkout "$@"; return; }
    git checkout ${ git branch -a | perl -pe 's~[* ]*(remotes/origin/)?~~' | sort -u | fzf ; }
} || echo "Not a git repository"
