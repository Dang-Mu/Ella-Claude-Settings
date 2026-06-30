#!/bin/bash
LOG=~/.claude/notify.log
TYPE=$(echo "$1" | tr '[:lower:]' '[:upper:]')  # Asks → ASKS, Stops → STOPS

# 현재 tmux 세션의 활성 윈도우와 이 pane이 속한 윈도우 비교
active_window=$(tmux display-message -p '#{active_window_index}' 2>/dev/null)
my_window=$(tmux display-message -t "$TMUX_PANE" -p '#{window_index}' 2>/dev/null)

{
  echo "--- $(date) ---"
  echo "type: $TYPE"
  echo "active_window: $active_window"
  echo "my_window: $my_window"
  echo "TMUX_PANE: $TMUX_PANE"
} >> "$LOG"

# 같은 tmux 창을 보고 있으면 알림 불필요
if [ "$active_window" = "$my_window" ] && [ -n "$active_window" ]; then
  echo "→ exit 0 (same window)" >> "$LOG"
  exit 0
fi

echo "→ sending macOS notification ($TYPE)" >> "$LOG"
osascript -e "display notification \"Claude $1\" with title \"Claude Code\""
