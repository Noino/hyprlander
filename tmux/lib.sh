#!/usr/bin/env bash
# NOTE ON TMUX TARGETS: a bare session name is NOT a safe -t argument. tmux parses '.'
# in a target as window.pane, so a session named "v5.24" (release branches need dots)
# resolves to "can't find pane: 24" and the session becomes unreachable -- and, worse,
# silently half-built, because `new-window -t <name>` fails while `-t <name>:<window>`
# succeeds. A trailing colon pins the whole string to the session part, and is harmless
# for ordinary names.
AMUX_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# shared styling for amux's fzf pickers (the session-create "modal"); per-call flags still win
export FZF_DEFAULT_OPTS="--layout=reverse --info=inline --border=rounded --margin=1 --padding=1 --pointer=▶ --marker=✓ --color=bg+:#283457,hl:#7aa2f7,hl+:#7dcfff,info:#7aa2f7,border:#7aa2f7,prompt:#7dcfff,pointer:#bb9af7,marker:#9ece6a,header:#565f89,label:#7aa2f7"

# ---- durable session state ---------------------------------------------------------
# tmux set-environment vars die with the session (and tmux-resurrect never restored them
# either -- see the AMUX_SERVICES note in dev.sh). Anything teardown needs must therefore
# live on disk: without this, killing a session by hand left `amux rm` unable to resolve
# its template, so teardown silently degraded to "kill session" and the worktrees were
# orphaned with no supported way to clean them up.
AMUX_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/amux"

# task names double as directory and tmux session names; slashes would nest the state dir
_amux_state_key() { printf '%s' "${1//\//-}"; }

amux_state_set() {  # <task> <key> <value>
  local task key
  task=$(_amux_state_key "$1"); key="$2"
  [[ -z "$task" || -z "$key" ]] && return 1
  mkdir -p "$AMUX_STATE/$task" || return 1
  printf '%s\n' "$3" > "$AMUX_STATE/$task/$key"
}

amux_state_get() {  # <task> <key> -> value on stdout; nonzero if unset
  local task key
  task=$(_amux_state_key "$1"); key="$2"
  [[ -z "$task" || -z "$key" ]] && return 1
  [[ -f "$AMUX_STATE/$task/$key" ]] || return 1
  cat "$AMUX_STATE/$task/$key"
}

amux_state_clear() {  # <task>
  local task; task=$(_amux_state_key "$1")
  [[ -n "$task" && -d "$AMUX_STATE/$task" ]] && rm -rf "${AMUX_STATE:?}/$task"
  return 0
}

tmux_goto() {
  [[ -n "$TMUX" ]] && tmux switch-client -t "$1:" || tmux attach -t "$1:"
}

# switch_clients_away <session>  — move every client attached to <session> to another
# session (explicit target; relative -n/-p is unreliable from inside a popup)
switch_clients_away() {
  local target="$1" other
  other=$(tmux list-sessions -F '#S' 2>/dev/null | grep -vxF "$target" | head -1)
  [[ -z "$other" ]] && return 0   # nothing else to switch to
  tmux list-clients -t "$target:" -F '#{client_name}' 2>/dev/null | while read -r c; do
    [[ -n "$c" ]] && tmux switch-client -c "$c" -t "$other"
  done
}

# kill_session_safely <session>  — swap attached clients away first, so killing the
# currently-attached session doesn't drop the client (tmux exit), then kill.
kill_session_safely() {
  switch_clients_away "$1"
  tmux kill-session -t "$1:" 2>/dev/null
}

# repo_default <dir>  — returns default branch name for repo (via origin/HEAD, falls back to master)
repo_default() {
  git -C "$1" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|origin/||' \
    || echo "master"
}

# pick_base <repo> <task>  — fzf branch list with repo default pre-selected; falls back to default on cancel
# The character class MUST include '+': `git branch` prefixes a branch checked out in
# another worktree with "+ ", and leaving it in produced a bogus duplicate entry ("+ master"
# alongside "master") that is not a valid ref.
pick_base() {
  local repo="$1" task="$2" default
  default=$(repo_default "$repo")
  git -C "$repo" branch -a 2>/dev/null \
    | perl -pe 's~[*+ ]*(remotes/origin/)?~~' | sort -u \
    | fzf --prompt="  " --border-label=" base branch for $task " --query="$default" --height=100% \
    || echo "$default"
}

# branch_checked_out_at <repo> <branch>  — prints the worktree path holding <branch>, if
# any. git refuses to check the same branch out twice (needs -f), so a branch parked in
# some other worktree is a hard blocker for creating a new one.
branch_checked_out_at() {
  git -C "$1" worktree list --porcelain 2>/dev/null \
    | awk -v b="branch refs/heads/$2" '/^worktree /{p=$2} $0==b{print p; exit}'
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
# KEEP IN SYNC with docker-setup/dev-services.lib:ds_wt_dirty, which answers the same
# question for `dev-services wt rm`. These two copies have already drifted into the
# identical bug twice (the missing positive ref below, and treating a squash-merged
# branch whose upstream was pruned as unpushed work).
# NB: the `--not --remotes` checks below MUST name HEAD explicitly. `git log --not
# --remotes` with no positive ref does not fall back to HEAD (any rev argument
# suppresses that default), so it always returned empty -- the "branch not pushed" and
# "detached HEAD" guards silently never fired, and amux rm would delete worktrees
# holding unpushed commits believing them clean.
check_git_clean() {
  local dir="$1" label="$2"
  [[ -d "$dir" ]] || return 0
  git -C "$dir" rev-parse --git-dir &>/dev/null || return 0
  # initialised, not merely declared: bare `local x` leaves x UNSET, which aborts the
  # function under `set -u` (as the drift guard in docker-setup/tests/run.sh runs it)
  local dirty="" unpushed="" branch=""
  dirty=$(git -C "$dir" status --porcelain 2>/dev/null)
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
  # $unpushed always holds a short REASON string, never a commit list, so the message
  # below can print what was actually objected to.
  #
  # Branch order and reason wording are kept IDENTICAL to ds_wt_dirty in
  # docker-setup/dev-services.lib so the two can be diffed and machine-compared. They stay
  # separate implementations on purpose: amux runs on machines that have no dev-services.
  if [[ -z "$branch" ]]; then
    [[ -n "$(git -C "$dir" log --oneline HEAD --not --remotes 2>/dev/null)" ]] \
      && unpushed="detached HEAD with commits on no remote"
  elif git -C "$dir" rev-parse --abbrev-ref "@{u}" &>/dev/null; then
    [[ -n "$(git -C "$dir" log "@{u}..HEAD" --oneline 2>/dev/null)" ]] && unpushed="unpushed commits"
  elif git -C "$dir" rev-parse --verify "origin/$branch" &>/dev/null; then
    # on the remote, just no upstream tracking configured (normal for bare-repo worktrees)
    [[ -n "$(git -C "$dir" log "origin/$branch..HEAD" --oneline 2>/dev/null)" ]] && unpushed="unpushed commits"
  elif [[ -n "$(git -C "$dir" config --get "branch.$branch.merge" 2>/dev/null)" ]]; then
    # Upstream IS configured but its remote-tracking ref is gone: the branch was published
    # and later deleted upstream -- ordinary post-merge PR cleanup. A squash-merge rewrites
    # SHAs so the local commits really are on no remote, meaning raw reachability cannot
    # tell merged from abandoned; look for the ticket id across the remotes instead.
    local ticket; ticket=$(printf '%s' "$branch" | grep -oE '[A-Z]{2,}-[0-9]+' | head -1)
    if [[ -z "$ticket" || -z "$(git -C "$dir" log --remotes --oneline --grep="$ticket" -1 2>/dev/null)" ]]; then
      unpushed="upstream branch deleted and nothing mentioning its ticket is on any remote (abandoned PR?)"
    fi
  else
    [[ -n "$(git -C "$dir" log --oneline HEAD --not --remotes 2>/dev/null)" ]] \
      && unpushed="branch never pushed"
  fi
  [[ -z "$dirty" && -z "$unpushed" ]] && return 0
  # reason assembled exactly as ds_wt_dirty does, so the two are byte-comparable
  local reason=""
  [[ -n "$dirty" ]] && reason="uncommitted changes"
  [[ -n "$unpushed" ]] && reason="${reason:+$reason + }$unpushed"
  echo "  ! $label: $reason"
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
