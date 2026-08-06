#!/usr/bin/env bash
# tmux status-right renderer: last few recently-attached sessions (excluding the
# current one) as clickable tabs. Click uses tmux's built-in range=session|<id>
# mouse range -- the default `MouseDown1Status -> switch-client -t =` binding
# already resolves `=` to that session, no custom key binding needed.
cur="$(tmux display-message -p '#S' 2>/dev/null)"
# kept small on purpose: 3 tabs, names capped at 16 chars. Real session names here run
# 50+ chars (ticket-style); a handful of those would starve the window list for room
# regardless of which edge tmux's own status-right-length truncation clips from.
tmux list-sessions -F '#{session_last_attached}|#{session_id}|#{session_name}' 2>/dev/null \
  | sort -t'|' -k1,1 -rn \
  | awk -F'|' -v cur="$cur" '$3 != cur' \
  | head -3 \
  | while IFS='|' read -r _ts id name; do
      short="$name"
      [ "${#short}" -gt 16 ] && short="${short:0:15}…"
      printf '#[range=session|%s,fg=colour244] %s #[norange,default]' "$id" "$short"
    done
