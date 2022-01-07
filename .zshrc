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


if [[ "$(hostname)" == *"fedora"* ]]; then
    plugins+=(
        apt
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
setopt EXTENDED_HISTORY
setopt HIST_BEEP
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

export HISTFILE=~/.zsh_history
export HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=true
export HISTORY_SUBSTRING_SEARCH_FUZZY=true
export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND=default
export HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND=default
export HISTSIZE=50000
export SAVEHIST=10000

# QOL, self-explanatory
if [[ "$(hostname)" == *"fedora"* ]] || [[ "$(hostname)" == *"ubuntu"* ]]; then
    EDITOR=/usr/bin/nvim

    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    source /usr/share/fzf/shell/key-bindings.zsh
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
    EDITOR=/opt/homebrew/bin/nvim

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

# Confidential
if [[ "$(whoami)" == "dmitry" ]] && [[ "$(hostname)" != *"server"* ]]; then
    source ~/.aliases.zsh
fi

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


