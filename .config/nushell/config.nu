# config.nu - Main Nushell configuration file
# See https://www.nushell.sh/book/configuration.html

$env.config = ($env.config? | default {})

# Disable welcome banner
$env.config.show_banner = false

# History settings (SQLite queryable history)
$env.config.history = {
    file_format: "sqlite"
    max_size: 10_000_000
    sync_on_enter: true
    isolation: false
    ignore_space_prefixed: true
}

# Completions and styling
$env.config.completions = {
    case_sensitive: false
    quick: true
    partial: true
    algorithm: "prefix"
    external: {
        enable: true
        max_results: 10000
    }
}

$env.config.edit_mode = "emacs"

# Load integrations and aliases
use starship.nu
source zoxide.nu
source mise.nu
source aliases.nu
