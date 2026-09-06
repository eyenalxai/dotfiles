# aliases.nu - Shell aliases and custom commands

# Editor
alias n = nvim

# Node / Package managers
alias npx = bunx

# Viewers & Navigation
alias ls = ls -a
alias cat = bat --plain --paging=never

# JSON schema helper
alias json-schema = jq --argjson nullable true 'include "schema"; schema'

# System control
alias shutdown = hyprshutdown -t 'Shutting down...' --post-cmd 'shutdown -P 0'
alias reboot = hyprshutdown -t 'Restarting...' --post-cmd 'reboot'
alias logout = hyprshutdown

# Arch / Pacman / AUR helpers
def yaas [...args: string] {
    ^yay -S --noconfirm ...$args
}

def yaasu [] {
    print "Running system upgrade..."
    ^sudo pacman -Suy --noconfirm
    ^yay -Suy --diffmenu
}

def yaac [] {
    let result = (do { ^yay -Qdtq } | complete)
    if $result.exit_code == 0 {
        let orphans = ($result.stdout | lines | str trim | where { |it| $it != "" })
        if ($orphans | is-not-empty) {
            print $"Removing ($orphans | length) orphan packages..."
            ^yay -Rscnd ...$orphans
        } else {
            print "No orphan packages found."
        }
    } else {
        print "No orphan packages found."
    }
}
