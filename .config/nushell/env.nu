# env.nu - Environment variables and startup configuration
#
# This file is loaded before config.nu and contains environment-specific setup.

# Omarchy path (used by env-bootstrap)
$env.OMARCHY_PATH = (
    if ("/etc/omarchy.conf" | path exists) {
        let conf = (open /etc/omarchy.conf | lines | get 0? | default "")
        if ($conf | str trim | is-not-empty) {
            $conf | str trim
        } else {
            "/usr/share/omarchy"
        }
    } else {
        "/usr/share/omarchy"
    }
)

# User-level tool directories
let user_paths = [
    $"($env.HOME)/.local/bin"
    $"($env.HOME)/.local/share/bin"
    $"($env.HOME)/.cargo/bin"
    $"($env.HOME)/go/bin"
    $"($env.HOME)/.local/share/mise/shims"
]

# Prepend Omarchy bin if in dev-link mode
let extra_paths = if $env.OMARCHY_PATH != "/usr/share/omarchy" {
    [$"($env.OMARCHY_PATH)/bin"] ++ $user_paths
} else {
    $user_paths
}

# Append active paths to PATH
$env.PATH = ($env.PATH | prepend ($extra_paths | where { |p| $p | path exists }) | uniq)

# Default editor
$env.EDITOR = "nvim"

# 1Password SSH Agent socket
let macos_1p_sock = $"($env.HOME)/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
let linux_1p_sock = $"($env.HOME)/.1password/agent.sock"

if ($macos_1p_sock | path exists) {
    $env.SSH_AUTH_SOCK = $macos_1p_sock
} else if ($linux_1p_sock | path exists) {
    $env.SSH_AUTH_SOCK = $linux_1p_sock
}

# Docker socket (Linux)
let runtime_dir = ($env.XDG_RUNTIME_DIR? | default $"/run/user/(^id -u)")
$env.DOCKER_HOST = $"unix://($runtime_dir)/docker.sock"

# Starship prompt configuration
let starship_config = $"($env.HOME)/.config/starship/starship.toml"
if ($starship_config | path exists) {
    $env.STARSHIP_CONFIG = $starship_config
}

# Go path
$env.GOPATH = $"($env.HOME)/go"
