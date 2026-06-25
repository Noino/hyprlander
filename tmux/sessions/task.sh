#!/usr/bin/env bash
# amux task <name> — task session; worktree-aware if in bare repo or linked worktree
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../lib.sh"

load() {
  TASK="$1"
  if [[ -z "$TASK" ]]; then
    read -rp "session name: " TASK
    [[ -z "$TASK" ]] && return 0
  fi

  local DIR; DIR="$(pwd)"

  if [[ "$(git -C "$DIR" rev-parse --is-bare-repository 2>/dev/null)" == "true" ]]; then
    local worktree="$DIR/$TASK"
    if [[ ! -d "$worktree" ]]; then
      echo "→ creating worktree: $TASK"
      if ! git -C "$DIR" worktree add "$TASK" "$TASK" 2>/dev/null; then
        local base; base=$(pick_base "$DIR" "$TASK")
        git -C "$DIR" worktree add -b "$TASK" "$TASK" "$base" || \
          { echo "failed to create worktree $TASK"; return 1; }
      fi
    fi
    DIR="$worktree"
  fi

  tmux has-session -t "$TASK" 2>/dev/null && tmux_goto "$TASK" && return

  tmux new-session -d -s "$TASK" -c "$DIR" -n nvim
  tmux set-environment -t "$TASK" AMUX_TEMPLATE "task"
  tmux set-environment -t "$TASK" AMUX_DIR "$DIR"

  tmux send-keys -t "$TASK:nvim" "nvim ." Enter
  tmux split-window -h -t "$TASK:nvim" -c "$DIR"
  tmux send-keys -t "$TASK:nvim" "claude --resume 2>/dev/null || claude" Enter

  tmux new-window -t "$TASK" -n bash -c "$DIR"

  tmux select-window -t "$TASK:nvim"
  tmux select-pane -t "$TASK:nvim.1"
  tmux_goto "$TASK"
}

unload() {
  TASK="$1"
  local dir
  dir=$(tmux showenv -t "$TASK" AMUX_DIR 2>/dev/null | cut -d= -f2-)

  if [[ -n "$dir" ]]; then
    guard_clean "$TASK" "$dir" || return 1
  else
    echo "  ! AMUX_DIR not recorded for '$TASK' — guard skipped, worktrees not cleaned" >&2
  fi

  if [[ -n "$dir" ]] && is_linked_worktree "$dir"; then
    local main_repo
    main_repo=$(git -C "$dir" rev-parse --git-common-dir 2>/dev/null)
    git -C "$main_repo" worktree remove "$dir" --force 2>/dev/null
    git -C "$main_repo" worktree prune 2>/dev/null
  fi

  tmux kill-session -t "$TASK" 2>/dev/null
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && load "$@"
