#!/usr/bin/env bash
# Credential source for aerc's source-cred-cmd / outgoing-cred-cmd.
#
# Usage: get-cred.sh [--refresh] <op-secret-reference>
#
# 1Password's app integration authorizes the CLI per terminal session and
# revokes that authorization when the 1Password app locks, so calling
# `op read` directly would prompt for authorization on every aerc start.
# Instead the secret is read from 1Password once and cached in the login
# keyring; later calls are served from there without any prompt.
#
# After rotating the password in 1Password, run:
#   ~/.config/aerc/get-cred.sh --refresh op://Private/Migadu/main-mailbox-password

set -u

refresh=
if [[ ${1:-} == --refresh ]]; then
  refresh=1
  shift
fi

ref=${1:-}
if [[ -z $ref ]]; then
  echo "usage: ${0##*/} [--refresh] <op-secret-reference>" >&2
  exit 1
fi

if [[ -z $refresh ]]; then
  if cached=$(secret-tool lookup aerc-secret "$ref" 2>/dev/null); then
    printf '%s\n' "$cached"
    exit 0
  fi
fi

secret=$(op read "$ref") || exit 1

# Cache for next time; if the keyring is unavailable, still hand the secret
# to aerc so the account keeps working.
if ! printf '%s' "$secret" | secret-tool store --label="aerc: $ref" \
    aerc-secret "$ref" 2>/dev/null; then
  printf '%s\n' "$secret"
  exit 0
fi

printf '%s\n' "$secret"
