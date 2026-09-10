#!/usr/bin/env bash
# Click action for aerc's "new mail" desktop notification.
#
# Focuses the aerc window and opens the message that triggered the
# notification, starting aerc in a terminal first if it isn't running.
#
# Usage: open-message.sh <account> <folder> <message-id>

set -u

account=${1:-}
folder=${2:-}
message_id=${3:-}

runtime_dir=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
sock=$runtime_dir/aerc.sock
# aerc sets its terminal window title to "aerc" on startup (lib/ui/ui.go).
window_title=aerc

hypr() { hyprctl "$@" 2>/dev/null; }

aerc_running() {
  socat -u /dev/null "UNIX-CONNECT:$sock" 2>/dev/null
}

aerc_cmd() {
  command aerc -A /dev/null "$@" >/dev/null 2>&1 || true
}

quote_arg() {
  # aerc parses its own command lines; single-quote the value for it.
  local value=${1//\'/\'\\\'\'}
  printf "'%s'" "$value"
}

window_for_title() {
  hypr clients -j | jq -r --arg title "$window_title" \
    'first(.[] | select((.title // "") == $title) | .address) // empty'
}

focus_window() {
  [[ -n ${1:-} ]] || return 0
  # Current Hyprland takes Lua dispatches; older builds take the plain form.
  hypr dispatch "hl.dsp.focus({ window = \"address:$1\" })" >/dev/null \
    || hypr dispatch focuswindow "address:$1" >/dev/null \
    || true
}

wait_for_new_window() {
  # Wait for a window titled $window_title whose address is not in $1.
  local existing=$1 addr
  for _ in $(seq 1 200); do
    addr=$(window_for_title)
    if [[ -n $addr ]] && ! grep -qxF "$addr" <<<"$existing"; then
      printf '%s' "$addr"
      return 0
    fi
    sleep 0.1
  done
  return 1
}

selection_matches() {
  # True once aerc's selected message is the one we want. `:pipe -m` dumps the
  # full message (fetched with BODY.PEEK[], so nothing is marked read) through
  # `tee` into $1, and we compare its Message-Id header.
  local dump=$1 want=$2 line i
  for ((i = 0; i < 15; i++)); do
    if ((i % 5 == 0)); then
      aerc_cmd ":pipe -b -m tee $dump"
    fi
    line=$(grep -m1 -i '^message-id:' "$dump" 2>/dev/null) || true
    [[ $line == *"<$want>"* ]] && return 0
    sleep 0.1
  done
  return 1
}

open_message() {
  if [[ -n $account && -n $folder ]]; then
    aerc_cmd ":cf -a $(quote_arg "$account") $(quote_arg "$folder")"
    sleep 0.4
  fi
  aerc_cmd ':clear'
  [[ -n $message_id ]] || return 0

  local mid=${message_id#<}
  mid=${mid%>}
  local dump=$runtime_dir/aerc-open-message.dump
  rm -f "$dump"
  # Searching is asynchronous; poll the selection before opening it so a slow
  # search (e.g. right after the folder was reloaded) can't view the wrong
  # message. Re-issue the search in case a pending reload reset its results.
  local attempt
  for attempt in 1 2 3; do
    aerc_cmd ":search -H $(quote_arg "Message-Id:<$mid>")"
    sleep 0.25
    if selection_matches "$dump" "$mid"; then
      aerc_cmd ':view'
      return 0
    fi
  done
}

if aerc_running; then
  focus_window "$(window_for_title)"
  open_message
else
  existing=$(hypr clients -j 2>/dev/null | jq -r '.[].address' | sort)
  omarchy-launch-terminal aerc >/dev/null 2>&1 &
  addr=$(wait_for_new_window "$existing") || addr=
  focus_window "$addr"
  # aerc may need a while to come up: it can be blocked on an `op read`
  # credential command waiting for 1Password to be unlocked.
  for _ in $(seq 1 600); do
    aerc_running && break
    sleep 0.1
  done
  sleep 1
  open_message
fi
