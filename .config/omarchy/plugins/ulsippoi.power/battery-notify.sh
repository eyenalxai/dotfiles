#!/bin/bash

# Low-battery notification lifecycle for the power panel.
#
# omarchy-battery-low always posts a fresh persistent (critical) toast, so the
# panel's repeated warnings would stack identical notifications on screen. This
# wrapper clears any existing low-battery toast before posting a new one, and
# exposes --clear so the panel can drop them the moment charging starts.
#
# Usage: battery-notify.sh <percentage>
#        battery-notify.sh --clear

set -euo pipefail

# The summary omarchy-battery-low gives its toast. omarchy-notification-dismiss
# matches on a substring, so this must stay in sync with that command.
notification_summary="Time to recharge!"

clear_notifications() {
  omarchy-notification-dismiss "$notification_summary" >/dev/null 2>&1 || true
}

case "${1:-}" in
  --clear)
    clear_notifications
    ;;
  "" | *[!0-9]*)
    echo "Usage: battery-notify.sh <percentage> | --clear" >&2
    exit 2
    ;;
  *)
    # Drop the previous warning so only the newest one is ever on screen.
    clear_notifications
    omarchy-battery-low "$1"
    ;;
esac
