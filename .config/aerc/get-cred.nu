#!/usr/bin/env nu
# Credential source for aerc's source-cred-cmd / outgoing-cred-cmd, and for
# the mail-watch notification service.
#
# Usage: get-cred.nu [--refresh] <op-secret-reference>
#
# 1Password's app integration authorizes its CLI per terminal session and
# revokes that authorization whenever the 1Password app locks, so calling
# `op read` directly would prompt for authorization on every aerc start.
# Instead the secret is read from 1Password once and cached in the login
# keyring; later calls are served from there without any prompt.
#
# After rotating the password in 1Password, refresh the cached copy with:
#   nu ~/.config/aerc/get-cred.nu --refresh op://Private/Migadu/main-mailbox-password

const SERVICE = "aerc-secret"

def keyring-lookup [ref: string]: nothing -> string {
  let r = (^secret-tool lookup $SERVICE $ref | complete)
  if $r.exit_code == 0 { $r.stdout | str trim } else { "" }
}

def keyring-store [ref: string, secret: string] {
  $secret | ^secret-tool store --label $"aerc: ($ref)" $SERVICE $ref | complete | ignore
}

def read-op [ref: string]: nothing -> string {
  let r = (^op read $ref | complete)
  if $r.exit_code != 0 {
    let why = ($r.stderr | str trim)
    error make { msg: (if ($why | is-empty) { $"op read failed for ($ref)" } else { $why }) }
  }
  $r.stdout | str trim
}

# Return the secret behind an op:// reference, from the login keyring when
# possible and from 1Password on the first use (or after --refresh).
export def credential [--refresh, ref: string]: nothing -> string {
  if not $refresh {
    let cached = (keyring-lookup $ref)
    if not ($cached | is-empty) { return $cached }
  }
  let secret = (read-op $ref)
  if ($secret | is-empty) { error make { msg: $"no secret returned for ($ref)" } }
  keyring-store $ref $secret
  $secret
}

def main [--refresh, ref: string] {
  credential --refresh=$refresh $ref
}
