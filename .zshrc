# Path to your oh-my-zsh installation.
export ZSH="${HOME}/.oh-my-zsh"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    alias-finder
    git
    history-substring-search
    docker
    docker-compose
)

if [[ "$(hostname)" == *"fedora"* ]] || [[ "$(hostname)" == *"ubuntu"* ]]; then
    plugins+=(
        systemd
    )
fi

if [[ "$(hostname)" == *"fedora"* ]]; then
    plugins+=(
        dnf
    )
fi

if [[ "$(hostname)" == *"server"* ]]; then
    plugins+=(
        keychain
        gpg-agent
        ssh-agent
    )
fi

# Disable zsh substitution/autocomplete with URL and backslashes
DISABLE_MAGIC_FUNCTIONS=true

# Activate
source $ZSH/oh-my-zsh.sh

# Starship Prompt
eval "$(starship init zsh)"
export STARSHIP_CONFIG=~/.config/starship/starship.toml

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000

export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt HIST_BEEP                 # Beep when accessing nonexistent history.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.

# QOL, self-explanatory
if [[ "$(hostname)" == *"fedora"* ]] || [[ "$(hostname)" == *"ubuntu"* ]]; then
    EDITOR=/usr/bin/nvim

    if [[ "$(whoami)" != "root" ]] && [[ "$(hostname)" != *"server"* ]]; then
        source ~/.aliases.zsh
    fi

    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    if [[ "$(hostname)" == *"ubuntu"* ]]; then
        source /usr/share/doc/fzf/examples/key-bindings.zsh
    elif [[ "$(hostname)" == *"fedora"* ]]; then 
        source /usr/share/fzf/shell/key-bindings.zsh
    fi
fi

if [[ "$(uname -s)" == "Darwin" ]] && [[ "$(whoami)" != "root" ]]; then
    EDITOR=/opt/homebrew/bin/nvim

    source ~/.aliases.zsh
    source "${HOME}/.fzf.zsh"
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh" || true
fi

export FZF_DEFAULT_COMMAND='rg --files --hidden -g "!.git" '
export ZSH_ALIAS_FINDER_AUTOMATIC=true

# My 
PATH="${HOME}/.cargo/bin:${HOME}/.local/bin:${PATH}"

# Zoxide
eval "$(zoxide init zsh)"

# GOPATH
export GOPATH=${HOME}/.go
export PATH=${PATH}:${GOPATH}/bin

# Node
export N_PREFIX=$HOME/.n
export PATH=$N_PREFIX/bin:$PATH

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
alias garbage-commit='git commit -m "$(curl -sL commit.takx.xyz)"'
alias gcg="gaa && garbage-commit"
alias rg="rg -i"
alias v=nvim
alias la="exa --long -a"
alias sudo="sudo "
alias python=python3

if [[ "$(uname -s)" == "Darwin" ]]; then
    alias sed=gsed
fi


# Generate .gitignore
function gi() { 
    curl -sL https://www.toptal.com/developers/gitignore/api/$@ >> .gitignore
    sed -i '/^#/ d' .gitignore
    sed -i '/^$/d' .gitignore
}

_gitignoreio_get_command_list() {
  curl -sL https://www.toptal.com/developers/gitignore/api/list | tr "," "\n"
}

_gitignoreio () {
  compset -P '*,'
  compadd -S '' `_gitignoreio_get_command_list`
}

compdef _gitignoreio gi



export PATH="$HOME/.poetry/bin:$PATH"
