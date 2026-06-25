# amux

Tmux session manager. Loads named session layouts, falls back to bare `tmux new-session`.

## Usage

```sh
amux                        # attach (choose-session if multiple); launch 'amux new' if none
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

- **Bare repo dir** → creates worktree `$TASK` (tries existing branch, else new from HEAD), opens there
- **Linked worktree dir** → opens in place
- **Regular dir** → vanilla open

| Window | Layout                    |
|--------|---------------------------|
| nvim   | nvim . \| claude (vsplit) |
| bash   | blank                     |

On `amux rm`: guard checks for uncommitted/unpushed changes. If dir is a linked worktree (created or pre-existing and clean), tears it down. Native `tmux kill-session` bypasses all guards.

## Layout: dev

Worktrees across crp, majakka, netpay at `~/Linkity/code/<repo>/<name>/`.

On `amux dev DEV-123`:
- Scans all repos for branch matching `*DEV-123*`
- Found in remote → `git worktree add` on that branch; repos without the branch get base branch worktree instead
- Not found anywhere → fzf pick base, creates new branch + worktree in all repos

| Window   | Layout                                   |
|----------|------------------------------------------|
| crp      | nvim . \| claude (vsplit) — worktree     |
| majakka  | nvim . \| claude (vsplit) — worktree     |
| netpay   | nvim . \| claude (vsplit) — worktree     |

`amux dev master` additionally opens:

| Window   | Layout                                          |
|----------|-------------------------------------------------|
| services | docker compose up \| vite (npm i first) / logs  |
| ctrl     | wait for mariadb → run doctrine migrations      |

On `amux rm`: guards uncommitted/unpushed in all worktrees. `master` also runs `docker compose down`. Use `--force` to skip guard.

## Telescope session picker (`prefix+s`)

| Key     | Action                               |
|---------|--------------------------------------|
| Enter   | switch to session                    |
| `alt+a` | create new session                   |
| `alt+d` | `amux rm` (smart teardown + refresh) |
| `alt+x` | vanilla kill with confirm + refresh  |
| `alt+r` | rename session                       |

Deleting current session switches client to next session before killing.

## Template protocol

Templates in `sessions/` or `sessions.local/` must define:

```sh
load()    # create session — called by amux task/dev/new
unload()  # teardown — called by amux rm
suggest() # optional: echo branch/name suggestions for amux new fzf
```

Helpers via `lib.sh`: `tmux_goto`, `repo_default`, `pick_base`, `is_linked_worktree`, `check_git_clean`, `guard_clean`.

## Adding a session

```sh
#!/usr/bin/env bash
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../lib.sh"

load() {
  tmux has-session -t myproj 2>/dev/null && tmux_goto myproj && return
  tmux new-session -d -s myproj -c ~/path/to/project -n nvim
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
