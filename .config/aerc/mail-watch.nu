#!/usr/bin/env nu
# Watches IMAP mailboxes and raises Omarchy desktop notifications for new mail.
#
# Independent of aerc: this service polls the mailboxes itself, so
# notifications arrive even when aerc isn't running. Clicking a notification
# runs open-in-aerc.nu, which starts aerc if needed and opens the message.
#
# Usage: mail-watch.nu [--once] [--dry-run] [--interval <duration>]
#
# Accounts come from aerc's accounts.conf (name, imap URL, default folder and
# the op:// reference in source-cred-cmd). The last seen UID per mailbox is
# kept in ~/.local/state/mail-watch/state.json.

use ./get-cred.nu credential

const DEFAULT_INTERVAL = 20sec

def open-script []: nothing -> string {
  $env.HOME | path join ".config/aerc/open-in-aerc.nu"
}

def accounts-file []: nothing -> string {
  $env.HOME | path join ".config/aerc/accounts.conf"
}

def state-file []: nothing -> string {
  $env.HOME | path join ".local/state/mail-watch/state.json"
}

# --- accounts.conf parsing ---------------------------------------------------

def parse-accounts []: nothing -> list {
  let raw = (open --raw (accounts-file))
  let lines = (
    $raw | lines
    | each {|l| $l | str trim }
    | where {|l| ($l != "") and (not ($l | str starts-with "#")) }
  )
  mut accounts = []
  mut cur = {}
  mut name = ""
  for line in $lines {
    if ($line | str starts-with "[") {
      if $name != "" { $accounts = ($accounts | append ($cur | insert name $name)) }
      $name = ($line | str replace -r '^\[(.*)\]$' '$1')
      $cur = {}
    } else if $name != "" {
      let m = ($line | parse --regex '^(?<key>[A-Za-z0-9_-]+)\s*=\s*(?<value>.*)$')
      if not ($m | is-empty) {
        let row = ($m | first)
        $cur = ($cur | upsert ($row.key | str lowercase) ($row.value | str trim))
      }
    }
  }
  if $name != "" { $accounts = ($accounts | append ($cur | insert name $name)) }
  $accounts
}

def watch-targets []: nothing -> list {
  parse-accounts | each {|a|
    let source = ($a | get -o source | default "")
    let cred_cmd = ($a | get -o "source-cred-cmd" | default "")
    let m = ($source | parse --regex '^imaps://(?<user>[^@]+)@(?<host>[^:]+):(?<port>\d+)' | get -o 0)
    let ref = ($cred_cmd | parse --regex '(?<ref>op://\S+)' | get -o 0.ref | default "")
    if ($m == null) or ($ref == "") {
      null
    } else {
      {
        account: $a.name,
        folder: ($a | get -o default | default "INBOX"),
        user: ($m.user | url decode),
        host: $m.host,
        port: ($m.port | into int),
        ref: $ref,
      }
    }
  } | compact
}

# --- IMAP over curl ----------------------------------------------------------

def curl-escape [s: string]: nothing -> string {
  $s | str replace -a '\' '\\' | str replace -a '"' '\"'
}

def imap-request [
  host: string,
  port: int,
  user: string,
  password: string,
  folder: string,
  cmd: string,
]: nothing -> record {
  # The password goes through curl's config on stdin, never the command line.
  let cfg = $"user = \"(curl-escape $user):(curl-escape $password)\"\nsilent\nshow-error\n"
  $cfg | ^curl -K - --silent --show-error -X $cmd $"imaps://($host):($port)/($folder)" | complete
}

# --- header parsing ----------------------------------------------------------

def decode-word [enc: string, text: string]: nothing -> string {
  let e = ($enc | str lowercase)
  if $e == "b" {
    try { $text | str replace -r -a '\s' '' | decode base64 | decode utf-8 } catch { $text }
  } else if $e == "q" {
    try { $text | str replace -a '_' ' ' | str replace -r -a '=([0-9A-Fa-f]{2})' '%$1' | url decode } catch { $text }
  } else {
    $text
  }
}

def decode-header [s: string]: nothing -> string {
  # RFC 2047: decode any =?charset?B/Q?text?= words, dropping whitespace
  # between adjacent encoded words.
  mut out = ""
  mut rest = $s
  while ($rest =~ '\=\?') {
    let idx = ($rest | str index-of '=?')
    if $idx < 0 { break }
    $out += ($rest | str substring 0..<$idx)
    $rest = ($rest | str substring ($idx + 2)..)
    let m = ($rest | parse --regex '^(?<charset>[^?]+)\?(?<enc>[^?]+)\?(?<text>[^?]*)\?=(?<tail>.*)$')
    if ($m | is-empty) {
      $out += '=?'
      continue
    }
    let row = ($m | first)
    $out += (decode-word $row.enc $row.text)
    $rest = $row.tail
    if ($rest =~ '^\s+=\?') {
      $rest = ($rest | str replace -r '^\s+' '')
    }
  }
  $out + $rest
}

def parse-headers [raw: string]: nothing -> record {
  let unfolded = ($raw | str replace -a "\r\n" "\n" | str replace -r -a '\n[ \t]+' ' ')
  mut hdr = {}
  for line in ($unfolded | lines) {
    let m = ($line | parse --regex '^(?i)(?<name>[a-z][a-z0-9-]*):\s?(?<value>.*)$')
    if not ($m | is-empty) {
      let row = ($m | first)
      $hdr = ($hdr | upsert ($row.name | str lowercase) $row.value)
    }
  }
  $hdr
}

def sender-name [from: string]: nothing -> string {
  let m = ($from | parse --regex '^(?<name>.*)<(?<addr>[^>]*)>$' | get -o 0)
  if $m == null {
    decode-header $from
  } else {
    let n = ($m.name | str trim | str trim -c '"' | str trim)
    if ($n | is-empty) { ($m.addr | str trim) } else { decode-header $n }
  }
}

# --- state -------------------------------------------------------------------

def load-state [path: string]: nothing -> list {
  if ($path | path exists) {
    try { open --raw $path | from json } catch { [] }
  } else {
    []
  }
}

def save-state [path: string, state: list] {
  let dir = ($path | path dirname)
  if not ($dir | path exists) { mkdir $dir }
  $state | to json | save -f $path
}

def set-entry [state: list, entry: record]: nothing -> list {
  if ($state | where key == $entry.key | is-empty) {
    $state | append $entry
  } else {
    $state | each {|e| if $e.key == $entry.key { $entry } else { $e } }
  }
}

# --- notifications -----------------------------------------------------------

def aerc-focused []: nothing -> bool {
  let r = (^hyprctl activewindow -j | complete)
  if $r.exit_code != 0 { return false }
  let t = (try { $r.stdout | from json | get -o title | default "" } catch { "" })
  $t == "aerc"
}

def send-notification [from: string, subject: string, t: record, mid: string, dry_run: bool] {
  let who = (if ($from | is-empty) { $t.user } else { $from })
  let title = $"New mail from ($who)"
  let body = (if ($subject | is-empty) { "(no subject)" } else { $subject })

  if $dry_run {
    print $"DRY-RUN: ($title) | ($body) | ($t.account)/($t.folder) <($mid)>"
    return
  }
  if (aerc-focused) {
    print $"skip (aerc focused): ($title)"
    return
  }
  if ($mid | is-empty) {
    ^omarchy-notification-send --app-name aerc -u normal $title $body | complete | ignore
  } else {
    ^omarchy-notification-send --app-name aerc -u normal $title $body --exec /usr/bin/nu --no-config-file (open-script) $t.account $t.folder $mid | complete | ignore
  }
  print $"notified: ($title)"
}

# --- polling -----------------------------------------------------------------

def poll-target [t: record, secret: string, state: list, dry_run: bool]: nothing -> list {
  let key = $"($t.account)/($t.folder)"
  let res = (imap-request $t.host $t.port $t.user $secret $t.folder $"EXAMINE ($t.folder)")
  if $res.exit_code != 0 {
    print $"($key): EXAMINE failed: ($res.stderr | str trim)"
    return $state
  }
  let uidv = ($res.stdout | parse --regex 'UIDVALIDITY\s+(?<v>\d+)' | get -o 0.v | default "0" | into int)
  let next = ($res.stdout | parse --regex 'UIDNEXT\s+(?<v>\d+)' | get -o 0.v | default "0" | into int)
  if ($uidv == 0) or ($next == 0) {
    print $"($key): could not read UIDVALIDITY/UIDNEXT"
    return $state
  }

  let prev = ($state | where key == $key | get -o 0)
  if ($prev == null) or ($prev.uidvalidity != $uidv) {
    # First sight of this mailbox (or the server renumbered it): remember where
    # it stands without notifying for the backlog.
    print $"($key): baseline at UID ($next - 1)"
    return (set-entry $state {key: $key, uidvalidity: $uidv, last_uid: ($next - 1)})
  }

  mut last = $prev.last_uid
  if ($next - 1) >= ($prev.last_uid + 1) {
    for uid in ($prev.last_uid + 1)..($next - 1) {
      let cmd = "UID FETCH " + ($uid | into string) + " (BODY.PEEK[HEADER.FIELDS (FROM SUBJECT MESSAGE-ID)])"
      let f = (imap-request $t.host $t.port $t.user $secret $t.folder $cmd)
      if $f.exit_code != 0 {
        print $"($key): fetch ($uid) failed: ($f.stderr | str trim)"
        break
      }
      let hdr = (parse-headers $f.stdout)
      let from_raw = ($hdr | get -o from | default "")
      let subject = (decode-header ($hdr | get -o subject | default ""))
      let mid = (
        ($hdr | get -o message-id | default "")
        | str replace -r '^<' '' | str replace -r '>$' '' | str trim
      )
      send-notification (sender-name $from_raw) $subject $t $mid $dry_run
      $last = $uid
    }
  }
  set-entry $state {key: $key, uidvalidity: $uidv, last_uid: $last}
}

# --- main --------------------------------------------------------------------

# One poll wrapped so a broken mailbox can't stop the others; note that the
# error handler must not capture a mutable variable, hence this helper.
def poll-safe [t: record, state: list, dry_run: bool]: nothing -> list {
  try {
    poll-target $t (credential $t.ref) $state $dry_run
  } catch {|e|
    print $"($t.account): error: ($e.msg)"
    $state
  }
}

def main [--once, --dry-run, --interval: duration = $DEFAULT_INTERVAL] {
  let state_path = (state-file)
  let targets = (watch-targets)
  print $"mail-watch: ($targets | length) mailboxes, polling every ($interval)"
  loop {
    mut state = (load-state $state_path)
    for t in $targets {
      $state = (poll-safe $t $state $dry_run)
      save-state $state_path $state
    }
    if $once { break }
    sleep $interval
  }
}
