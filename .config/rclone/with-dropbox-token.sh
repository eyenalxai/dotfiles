#!/usr/bin/env bash
# Fetch the Dropbox OAuth token from the session keyring (libsecret) and run
# the given command with rclone's env-var remote configured. No secrets here.
set -euo pipefail
service="${RCLONE_KEYRING_SERVICE:-rclone-dropbox}"
token=$(secret-tool lookup service "$service") || true
token=${token%$'\n'}
if [ -z "$token" ]; then
  echo "with-dropbox-token: no token in keyring (service=$service)" >&2
  exit 1
fi
export RCLONE_CONFIG_DROPBOX_TYPE=dropbox
export RCLONE_CONFIG_DROPBOX_TOKEN="$token"
exec "$@"
