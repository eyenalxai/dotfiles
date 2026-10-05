#!/usr/bin/env nu
# Open the full OpenCode Go usage view in the floating terminal.
# Force colors: with output not on a TTY the usage command would otherwise
# render without color.
$env.config.use_ansi_coloring = "true"
source ~/.config/nushell/autoload/opencode-go-usage.nu
opencode-go-usage --history
