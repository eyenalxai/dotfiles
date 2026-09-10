#!/usr/bin/env nu
# Click action for the new-mail notifications raised by mail-watch.nu.
#
# Focuses the aerc window and opens the message that triggered the
# notification, starting aerc in a terminal first if it isn't running.
#
# Usage: open-in-aerc.nu <account> <folder> <message-id>

def runtime-dir []: nothing -> string {
  $env.XDG_RUNTIME_DIR? | default $"/run/user/(^id -u | complete | get stdout | str trim)"
}

def aerc-sock []: nothing -> string {
  (runtime-dir) | path join "aerc.sock"
}

def aerc-running []: nothing -> bool {
  let sock = (aerc-sock)
  if not ($sock | path exists) { return false }
  (^socat -u /dev/null $"UNIX-CONNECT:($sock)" | complete).exit_code == 0
}

def hypr-clients []: nothing -> list {
  let r = (^hyprctl clients -j | complete)
  if $r.exit_code != 0 { return [] }
  try { $r.stdout | from json } catch { [] }
}

def window-for-title [title: string]: nothing -> string {
  let hit = (hypr-clients | where title == $title | get -o 0.address)
  if $hit == null { "" } else { $hit }
}

def focus-window [addr: string] {
  if ($addr | is-empty) { return }
  # Current Hyprland takes Lua dispatches; older builds take the plain form.
  let lua = ('hl.dsp.focus({ window = "address:' + $addr + '" })')
  let r = (^hyprctl dispatch $lua | complete)
  if $r.exit_code != 0 {
    ^hyprctl dispatch focuswindow $"address:($addr)" | complete | ignore
  }
}

def quote-arg [value: string]: nothing -> string {
  # aerc parses its own command lines; single-quote the value for it.
  "'" + ($value | str replace -a "'" "'\\''") + "'"
}

def aerc-cmd [cmd: string] {
  ^timeout 8 aerc -A /dev/null $cmd | complete | ignore
}

def selection-matches [dump: string, want: string]: nothing -> bool {
  # True once aerc's selected message is the one we want. `:pipe -m` dumps the
  # full message (fetched with BODY.PEEK[], so nothing is marked read) through
  # `tee` into $dump, and we compare its Message-Id header.
  for i in 0..14 {
    if ($i mod 5) == 0 {
      aerc-cmd $":pipe -b -m tee ($dump)"
    }
    let text = (try { open --raw $dump } catch { "" })
    let line = ($text | lines | where {|l| $l | str lowercase | str starts-with "message-id:" } | get -o 0 | default "")
    if ($line | str contains $"<($want)>") { return true }
    sleep 100ms
  }
  false
}

def open-message [account: string, folder: string, message_id: string] {
  if not (($account | is-empty) or ($folder | is-empty)) {
    aerc-cmd $":cf -a (quote-arg $account) (quote-arg $folder)"
    sleep 400ms
  }
  aerc-cmd ":clear"
  if ($message_id | is-empty) { return }

  let mid = ($message_id | str replace -r '^<' '' | str replace -r '>$' '' | str trim)
  let dump = ((runtime-dir) | path join "aerc-open-message.dump")
  rm --force $dump
  # Searching is asynchronous; poll the selection before opening it so a slow
  # search (e.g. right after the folder was reloaded) can't view the wrong
  # message. Re-issue the search in case a pending reload reset its results.
  for _ in 1..3 {
    aerc-cmd $":search -H (quote-arg ('Message-Id:<' + $mid + '>'))"
    sleep 250ms
    if (selection-matches $dump $mid) {
      aerc-cmd ":view"
      return
    }
  }
}

def wait-for-new-window [existing: list<string>]: nothing -> string {
  # Wait for a window titled "aerc" whose address is not in $existing.
  for _ in 0..199 {
    let addr = (window-for-title "aerc")
    if ($addr != "") and (not ($existing | any {|a| $a == $addr })) {
      return $addr
    }
    sleep 100ms
  }
  ""
}

def main [account: string, folder: string, message_id: string] {
  if (aerc-running) {
    focus-window (window-for-title "aerc")
    open-message $account $folder $message_id
  } else {
    let clients = (hypr-clients)
    let existing = (if ($clients | is-empty) { [] } else { $clients | get address })
    # omarchy-launch-terminal waits for the terminal to exit, so it must be
    # detached; setsid -f returns at once while the terminal keeps running.
    ^setsid -f omarchy-launch-terminal aerc o+e> /dev/null
    let addr = (wait-for-new-window $existing)
    focus-window $addr
    # aerc can take a moment to finish connecting before IPC works.
    for _ in 0..599 {
      if (aerc-running) { break }
      sleep 100ms
    }
    sleep 1sec
    open-message $account $folder $message_id
  }
}
