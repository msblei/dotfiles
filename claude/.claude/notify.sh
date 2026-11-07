#!/usr/bin/env bash
# Usage:
#   notify.sh schedule <event-label> <message>   - Schedule a delayed notification
#   notify.sh cancel                              - Cancel any pending notification for this session

# Private ntfy topic lives in ~/.config/notify.env (untracked). See templates/notify.env.example
TOPIC=""
[ -f "$HOME/.config/notify.env" ] && . "$HOME/.config/notify.env"
BELL_DELAY=10
NTFY_DELAY=60
MARKER_DIR="/tmp/claude-notify"
LOG="/tmp/claude-notify.log"
mkdir -p "$MARKER_DIR"

HOOK_JSON=$(cat)

SESSION_ID=$(printf '%s' "$HOOK_JSON" | grep -oE '"session_id"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
[ -z "$SESSION_ID" ] && SESSION_ID="default"
MARKER="$MARKER_DIR/$SESSION_ID.flag"

find_user_tty() {
  # 1. Walk up parent process tree to find a real tty
  local pid=$PPID
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    [ -z "$pid" ] || [ "$pid" = "1" ] || [ "$pid" = "0" ] && break
    local t=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
    if [ -n "$t" ] && [ "$t" != "?" ]; then
      echo "/dev/$t"
      return
    fi
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  done
  # 2. SSH_TTY env var
  [ -n "$SSH_TTY" ] && { echo "$SSH_TTY"; return; }
  # 3. `who` first active session
  local w=$(who 2>/dev/null | awk 'NR==1 {print "/dev/"$2}')
  [ -n "$w" ] && { echo "$w"; return; }
}
USER_TTY=$(find_user_tty)
[ -z "$USER_TTY" ] && USER_TTY="/dev/tty"

case "$1" in
  schedule)
    EVENT="${2:-event}"
    MSG="${3:-Claude needs attention}"

    TRANSCRIPT=$(printf '%s' "$HOOK_JSON" | python3 -c "import sys,json
try: print(json.load(sys.stdin).get('transcript_path',''))
except: pass" 2>/dev/null)

    TITLE=""
    if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
      TITLE=$(tac "$TRANSCRIPT" 2>/dev/null | python3 -c "
import sys, json
for line in sys.stdin:
    try:
        d = json.loads(line)
        if d.get('aiTitle'):
            print(d['aiTitle']); break
    except: pass" 2>/dev/null)
    fi

    WINDOW=""
    if [ -n "$TMUX_PANE" ] && command -v tmux >/dev/null 2>&1; then
      WINDOW=$(tmux display-message -p -t "$TMUX_PANE" '#W' 2>/dev/null)
    fi
    [ -z "$WINDOW" ] && WINDOW=$(basename "$(pwd)" 2>/dev/null)

    PREFIX="Claude"
    [ -n "$WINDOW" ] && PREFIX="Claude [$WINDOW]"
    [ -n "$TITLE" ] && PREFIX="$PREFIX — $TITLE"

    # Per-schedule token: each subshell only fires if the marker still contains
    # ITS token. Prevents stale subshells from resurrecting after cancel+reschedule.
    TOKEN="$$-$(date +%s%N 2>/dev/null || date +%s)-$RANDOM"
    printf '%s' "$TOKEN" > "$MARKER"
    echo "$(date): $EVENT scheduled (title='$TITLE', window='$WINDOW', session=$SESSION_ID, token=$TOKEN, tty=$USER_TTY, bell=${BELL_DELAY}s ntfy=${NTFY_DELAY}s)" >> "$LOG"

    # Stage 1: terminal bell
    (
      sleep "$BELL_DELAY"
      CURRENT=$(cat "$MARKER" 2>/dev/null)
      if [ "$CURRENT" = "$TOKEN" ]; then
        echo "$(date): $EVENT bell rang after ${BELL_DELAY}s (→$USER_TTY)" >> "$LOG"
        printf '\a' > "$USER_TTY" 2>/dev/null
      fi
    ) </dev/null >/dev/null 2>&1 &
    disown 2>/dev/null

    # Stage 2: phone push (removes marker on fire, only if still ours)
    (
      sleep "$NTFY_DELAY"
      CURRENT=$(cat "$MARKER" 2>/dev/null)
      if [ "$CURRENT" = "$TOKEN" ]; then
        rm -f "$MARKER"
        if [ -z "$TOPIC" ]; then
          echo "$(date): $EVENT ntfy skipped after ${NTFY_DELAY}s (TOPIC not set in ~/.config/notify.env)" >> "$LOG"
        else
          echo "$(date): $EVENT ntfy pushed after ${NTFY_DELAY}s" >> "$LOG"
          curl -fsS --max-time 5 -H "Title: $PREFIX" -d "$MSG" "ntfy.sh/$TOPIC" >/dev/null 2>&1
        fi
      fi
    ) </dev/null >/dev/null 2>&1 &
    disown 2>/dev/null
    ;;

  cancel)
    if [ -f "$MARKER" ]; then
      rm -f "$MARKER"
      echo "$(date): pending notification cancelled (session=$SESSION_ID)" >> "$LOG"
    fi
    ;;
esac
