#!/bin/sh
# JSON snapshot of OpenCode Go usage for the bar widget.
set -eu
NU=$(command -v nu 2>/dev/null || true)
[ -n "$NU" ] || NU=/usr/bin/nu
exec "$NU" -c 'source ~/.config/nushell/autoload/opencode-go-usage.nu; opencode-go-usage --json'
