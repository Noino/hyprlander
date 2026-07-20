# amux

Tmux session manager. Loads named session layouts, falls back to bare `tmux new-session`.

## Usage

```sh
amux                        # attach (choose-tree picker if multiple); launch basic if none
amux at <name>              # attach specific session, error if missing
amux new                    # interactive: fzf template → template handles rest
amux new <tmpl> [args...]   # use specific template, pass args directly to load()
amux rm <name> [--force]    # smart teardown via template unload(); --force skips guard
```

`prefix+c` opens `amux new` popup. `prefix+s` opens telescope session picker.

## Session resolution

`amux new <tmpl>` looks for `<tmpl>.sh` in order:

1. `sessions.local/<tmpl>.sh` — local, gitignored
2. `sessions/<tmpl>.sh` — global, tracked

## Interactive new (`amux new`)

1. fzf: pick template (`basic`, `task`, `dev`, any `*.sh` in sessions/ + sessions.local/)
2. Template's `load()` handles the rest — name prompt, branch fzf, worktree setup

## Layout: task

Opens in `$PWD`. Worktree-aware:

- **Bare repo dir** → creates worktree `$TASK` (tries existing branch, else new from base), opens there
- **Linked worktree dir** → opens in place
- **Regular dir** → vanilla open

| Window | Layout                          |
|--------|---------------------------------|
| nvim   | nvim . \| launch-agent (vsplit) |
| bash   | blank                           |

On `amux rm`: guard checks for uncommitted/unpushed changes. If dir is a linked worktree (created or pre-existing and clean), tears it down. Native `tmux kill-session` bypasses all guards.

## Layout: dev

Multi-repo worktree layout: one window per repo, each opened at a worktree for the same task/branch name, checked out (or created) across all of them together. Repo list and paths are project-specific — see `sessions.local/dev.sh` for the concrete example (gitignored; add your own project's repos there).

| Window       | Layout                                      |
|--------------|---------------------------------------------|
| <per repo>   | nvim . \| launch-agent (vsplit) — worktree  |

A `dev` template can optionally kick off project-specific dev infra (e.g. a docker stack) as part of `load()`/`unload()` — again, project-specific; not part of the generic amux core.

On `amux rm`: guards uncommitted/unpushed in all worktrees. Use `--force` to skip guard.

## Services

The generic `dev` template hook above can call out to whatever local dev-infra CLI your project uses (start on `load()`, stop on `unload()` if it was running). This repo doesn't ship one — it's project-specific glue that lives in that project's own repo/docs.

## AI agent (`launch-agent`)

`launch-agent [session]` starts the configured AI agent with session resume support.
Set `AMUX_AI_AGENT` to switch agents (default: `claude`).

| Agent      | First run                              | Subsequent / resurrect              |
|------------|----------------------------------------|-------------------------------------|
| `claude`   | `claude --name <session>`              | `claude --resume <session>`         |
| `opencode` | `opencode` + send-keys `/rename` dance | `opencode --session <session>`      |
| other      | `exec $AMUX_AI_AGENT`                  | same                                |

## Telescope session picker (`prefix+s`)

| Key     | Action                               |
|---------|--------------------------------------|
| Enter   | switch to session                    |
| `alt+d` | `amux rm` (smart teardown + refresh) |
| `alt+x` | vanilla kill with confirm + refresh  |

Opens with the currently-attached session pre-selected. Deleting a session that a client is attached to swaps that client to another session first (via `kill_session_safely` in `lib.sh`), so removing the current session never drops you out of tmux.

## Template protocol

Templates in `sessions/` or `sessions.local/` must define:

```sh
load()    # create session — called by amux new
unload()  # teardown — called by amux rm
```

Helpers via `lib.sh`: `tmux_goto`, `repo_default`, `pick_base`, `is_linked_worktree`, `check_git_clean`, `guard_clean`.

## Adding a session

```sh
#!/usr/bin/env bash
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../lib.sh"

load() {
  tmux has-session -t myproj 2>/dev/null && tmux_goto myproj && return
  tmux new-session -d -s myproj -c ~/path/to/project -n nvim
  tmux set-environment -t myproj AMUX_TEMPLATE "myproj"
  tmux send-keys -t myproj:nvim "nvim ." Enter
  tmux_goto myproj
}

unload() {
  tmux kill-session -t myproj 2>/dev/null
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && load "$@"
```

## Session persistence

- **tmux-continuum** auto-saves every 5 min, auto-restores on tmux server start
- **systemd unit** `tmux-save.service` saves on graceful shutdown/reboot
- Manual save: `prefix + C-s C-s` — manual restore: `prefix + C-s r`
