#!/usr/bin/env bash
AMUX_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

tmux_goto() {
  [[ -n "$TMUX" ]] && tmux switch-client -t "$1" || tmux attach -t "$1"
}

# repo_default <dir>  — returns default branch name for repo (via origin/HEAD, falls back to master)
repo_default() {
  git -C "$1" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|origin/||' \
    || echo "master"
}

# pick_base <repo> <task>  — fzf branch list with repo default pre-selected; falls back to default on cancel
pick_base() {
  local repo="$1" task="$2"
  git -C "$repo" branch -a 2>/dev/null \
    | perl -pe 's~[* ]*(remotes/origin/)?~~' | sort -u \
    | fzf --prompt="base for $task: " --query="$(repo_default "$repo")" --height=15 \
    || repo_default "$repo"
}

# is_linked_worktree <dir>  — returns 0 if dir is a linked worktree (not main or bare)
is_linked_worktree() {
  local dir="$1"
  local gitdir common
  gitdir=$(git -C "$dir" rev-parse --git-dir 2>/dev/null) || return 1
  common=$(git -C "$dir" rev-parse --git-common-dir 2>/dev/null)
  [[ "$gitdir" != "$common" ]]
}

# check_git_clean <dir> <label>  — returns 1 and prints warning if dirty/unpushed
check_git_clean() {
  local dir="$1" label="$2"
  [[ -d "$dir" ]] || return 0
  git -C "$dir" rev-parse --git-dir &>/dev/null || return 0
  local dirty unpushed
  dirty=$(git -C "$dir" status --porcelain 2>/dev/null)
  unpushed=$(git -C "$dir" log "@{u}..HEAD" --oneline 2>/dev/null)
  [[ -z "$dirty" && -z "$unpushed" ]] && return 0
  echo "  ! $label:$([ -n "$dirty" ] && echo " uncommitted changes")$([ -n "$unpushed" ] && echo " unpushed commits")"
  return 1
}

# guard_clean <task> <dirs...>  — interactive/non-interactive gate, respects --force via $AMUX_FORCE
guard_clean() {
  local task="$1"; shift
  [[ "$AMUX_FORCE" == "--force" ]] && return 0
  local dirty=0
  for dir in "$@"; do
    check_git_clean "$dir" "$(basename "$dir")" || dirty=1
  done
  [[ $dirty -eq 0 ]] && return 0
  if [[ -t 0 ]]; then
    read -rp "Unclean repos above. Delete anyway? [y/N] " confirm
    [[ "$confirm" =~ ^[yY]$ ]] && return 0
    echo "aborted"; return 1
  else
    echo "aborted: unclean repos. Run 'amux rm $task --force' to override" >&2
    return 1
  fi
}
