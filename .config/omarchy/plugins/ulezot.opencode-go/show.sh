#!/bin/sh
# Open the full OpenCode Go usage view in the floating terminal.
set -eu
NU=$(command -v nu 2>/dev/null || true)
[ -n "$NU" ] || NU=/usr/bin/nu
# `nu -c` discards the command's return value, which the usage command reads as
# redirected output and renders without color. Force colors back on for the TTY.
exec "$NU" -c '$env.config.use_ansi_coloring = "true"; source ~/.config/nushell/autoload/opencode-go-usage.nu; opencode-go-usage'
