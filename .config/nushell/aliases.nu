# aliases.nu - Shell aliases and custom commands

# Editor
alias n = nvim

# Node / Package managers
alias npx = bunx

# 1Password shell plugins
alias ngrok = op plugin run -- ngrok

# Viewers & Navigation
alias ls = ls -a
alias cat = bat --plain --paging=never

# JSON schema helper
alias json-schema = jq --argjson nullable true 'include "schema"; schema'

# System control
alias shutdown = hyprshutdown -t 'Shutting down...' --post-cmd 'shutdown -P 0'
alias reboot = hyprshutdown -t 'Restarting...' --post-cmd 'reboot'
alias logout = hyprshutdown

# Reboot into Windows (one-shot EFI boot override)
def windows-reboot [] {
    let entries = (^efibootmgr | lines | parse -r '^Boot(?P<num>[0-9A-Fa-f]{4})\* (?P<desc>.*)$')
    let win = ($entries | where desc =~ '^Windows Boot Manager' | first)
    if ($win | is-empty) {
        print "Windows Boot Manager entry not found in efibootmgr"
        return
    }
    ^sudo efibootmgr --bootnext $win.num
    hyprshutdown -t 'Restarting into Windows...' --post-cmd 'reboot'
}

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

# Yadm maintenance
alias yadm-prune = nu ~/.config/yadm/scripts/prune_archives.nu
alias yadm-prune-archives = nu ~/.config/yadm/scripts/prune_archives.nu
