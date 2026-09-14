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
# Both the keyring and 1Password calls are bounded by a timeout, so an
# unanswered unlock or authorization prompt makes this command fail with an
# error instead of blocking its caller (mbsync exits non-zero; aerc reports
# the failure and retries on the next check).
#
# After rotating the password in 1Password, refresh the cached copy with:
#   nu ~/.config/aerc/get-cred.nu --refresh op://Private/Migadu/main-mailbox-password

const SERVICE = "aerc-secret"
const KEYRING_TIMEOUT = 30
const OP_TIMEOUT = 90

def keyring-lookup [ref: string]: nothing -> string {
  let r = (^timeout $KEYRING_TIMEOUT secret-tool lookup $SERVICE $ref | complete)
  if $r.exit_code == 0 { $r.stdout | str trim } else { "" }
}

def keyring-store [ref: string, secret: string] {
  $secret | ^timeout $KEYRING_TIMEOUT secret-tool store --label $"aerc: ($ref)" $SERVICE $ref | complete | ignore
}

def read-op [ref: string]: nothing -> string {
  let r = (^timeout $OP_TIMEOUT op read $ref | complete)
  if $r.exit_code != 0 {
    if $r.exit_code == 124 {
      error make { msg: $"timed out after ($OP_TIMEOUT)s waiting for 1Password; approve the prompt and retry" }
    }
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
