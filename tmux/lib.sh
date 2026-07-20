#!/usr/bin/env bash
AMUX_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# shared styling for amux's fzf pickers (the session-create "modal"); per-call flags still win
export FZF_DEFAULT_OPTS="--layout=reverse --info=inline --border=rounded --margin=1 --padding=1 --pointer=▶ --marker=✓ --color=bg+:#283457,hl:#7aa2f7,hl+:#7dcfff,info:#7aa2f7,border:#7aa2f7,prompt:#7dcfff,pointer:#bb9af7,marker:#9ece6a,header:#565f89,label:#7aa2f7"

tmux_goto() {
  [[ -n "$TMUX" ]] && tmux switch-client -t "$1" || tmux attach -t "$1"
}

# switch_clients_away <session>  — move every client attached to <session> to another
# session (explicit target; relative -n/-p is unreliable from inside a popup)
switch_clients_away() {
  local target="$1" other
  other=$(tmux list-sessions -F '#S' 2>/dev/null | grep -vxF "$target" | head -1)
  [[ -z "$other" ]] && return 0   # nothing else to switch to
  tmux list-clients -t "$target" -F '#{client_name}' 2>/dev/null | while read -r c; do
    [[ -n "$c" ]] && tmux switch-client -c "$c" -t "$other"
  done
}

# kill_session_safely <session>  — swap attached clients away first, so killing the
# currently-attached session doesn't drop the client (tmux exit), then kill.
kill_session_safely() {
  switch_clients_away "$1"
  tmux kill-session -t "$1" 2>/dev/null
}

# repo_default <dir>  — returns default branch name for repo (via origin/HEAD, falls back to master)
repo_default() {
  git -C "$1" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|origin/||' \
    || echo "master"
}

# pick_base <repo> <task>  — fzf branch list with repo default pre-selected; falls back to default on cancel
pick_base() {
  local repo="$1" task="$2" default
  default=$(repo_default "$repo")
  git -C "$repo" branch -a 2>/dev/null \
    | perl -pe 's~[* ]*(remotes/origin/)?~~' | sort -u \
    | fzf --prompt="  " --border-label=" base branch for $task " --query="$default" --height=100% \
    || echo "$default"
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
  local dirty unpushed branch
  dirty=$(git -C "$dir" status --porcelain 2>/dev/null)
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
  if [[ -z "$branch" ]]; then
    # detached HEAD — flag any commits not reachable from any remote
    local unreachable; unreachable=$(git -C "$dir" log --oneline --not --remotes 2>/dev/null)
    [[ -n "$unreachable" ]] && unpushed="detached HEAD with unreachable commits"
  elif git -C "$dir" rev-parse --abbrev-ref "@{u}" &>/dev/null; then
    unpushed=$(git -C "$dir" log "@{u}..HEAD" --oneline 2>/dev/null)
  elif ! git -C "$dir" rev-parse --verify "origin/$branch" &>/dev/null; then
    # branch not on remote — only flag if there are local-only commits
    local local_only; local_only=$(git -C "$dir" log --oneline --not --remotes 2>/dev/null)
    [[ -n "$local_only" ]] && unpushed="branch not pushed to origin"
  else
    unpushed=$(git -C "$dir" log "origin/$branch..HEAD" --oneline 2>/dev/null)
  fi
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
    read -rp "Unclean repos above. Uncommitted changes will be permanently lost. Delete anyway? [y/N] " confirm
    [[ "$confirm" =~ ^[yY]$ ]] && return 0
    echo "aborted"; return 1
  else
    echo "aborted: unclean repos. Run 'amux rm $task --force' to override" >&2
    return 1
  fi
}
