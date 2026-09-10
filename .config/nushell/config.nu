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

# Load integrations
use starship.nu
source zoxide.nu
source mise.nu

# mise.nu replaces $env.PATH with directories baked by `mise activate nu` on
# another machine (stale /home/ulezot entries), discarding the user dirs that
# env.nu prepends. Re-add ~/.local/bin ahead of the system paths so
# user-installed tools (e.g. a locally built opencode2) take precedence.
$env.PATH = ($env.PATH | prepend $"($env.HOME)/.local/bin" | uniq)

# Custom completions
source completions/git-completions.nu
source completions/yadm-completions.nu
use completions/systemctl-completions.nu *
source completions/pacman-completions.nu
source completions/yay-completions.nu
source completions/docker-completions.nu
source completions/docker-compose-completions.nu
source completions/pkill-completions.nu
source completions/op-completions.nu
source completions/zoxide-completions.nu

# Aliases and custom commands
source aliases.nu
