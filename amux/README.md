# amux

Tmux session manager. Loads named session layouts, falls back to bare `tmux new-session`.

## Usage

```sh
amux                # attach existing tmux or start bare session
amux master         # boot master session (all projects, nvim|claude per tab)
amux task <name>    # new simple task session (nvim|claude, git, srv)
amux dev <name>     # new dev session with worktrees + master layout (no ctrl)
amux <name>         # load named session layout or bare new-session
```

## Session resolution

`amux <name>` looks for `<name>.sh` in order:

1. `sessions.local/<name>.sh` — local, gitignored
2. `sessions/<name>.sh` — global, tracked

Falls back to `tmux new-session -A -s <name>` if no template found.

## Layout: master

| Window   | Layout                                        |
|----------|-----------------------------------------------|
| crp      | nvim . \| claude (vsplit)                     |
| majakka  | nvim . \| claude (vsplit)                     |
| netpay   | nvim . \| claude (vsplit)                     |
| services | docker \| vite (top) / log tail (bottom)      |

## Layout: task

| Window | Layout                    |
|--------|---------------------------|
| nvim   | nvim . \| claude (vsplit) |
| git    | git status                |
| srv    | blank                     |

## Layout: dev

Same as master minus ctrl. Each project window opens in its own git worktree at
`~/Linkity/code/<repo>-<name>/`.

On `amux dev DEV-123`:
- Scans crp, majakka, payrollnetcalculation for branch matching `*DEV-123*`
- Found → `git worktree add` from that branch
- Not found → fzf pick base (master / vX.XX), creates new branch + worktree

| Window   | Layout                                        |
|----------|-----------------------------------------------|
| crp      | nvim . \| claude (vsplit) — worktree          |
| majakka  | nvim . \| claude (vsplit) — worktree          |
| netpay   | nvim . \| claude (vsplit) — worktree          |
| services | docker \| vite (top) / log tail (bottom)      |

## Adding a session

Drop a `<name>.sh` in `sessions/` (shared) or `sessions.local/` (personal):

```sh
#!/usr/bin/env bash
tmux has-session -t myproj 2>/dev/null && tmux attach -t myproj && exit
tmux new-session -d -s myproj -c ~/path/to/project -n nvim
tmux send-keys -t myproj:nvim "nvim ." Enter
# ... more windows
tmux attach -t myproj
```

## Session persistence

- **tmux-continuum** auto-saves every 5 min, auto-restores on tmux server start
- **systemd unit** `tmux-save.service` saves on graceful shutdown/reboot
- Manual save: `prefix + C-s C-s` — manual restore: `prefix + C-s r`
