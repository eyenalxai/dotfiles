export ZSH="${HOME}/.oh-my-zsh"

# Plugins
plugins=(
    alias-finder
    git
    history-substring-search
    dotenv
)

# Disable zsh substitution/autocomplete with URL and backslashes
DISABLE_MAGIC_FUNCTIONS=true

# Activate
source $ZSH/oh-my-zsh.sh

# Aliases
source "${HOME}/.config/zsh/aliases.zsh"

# Proxy
# source "${HOME}/.config/zsh/proxy.zsh"

# Starship Prompt
eval "$(starship init zsh)"
export STARSHIP_CONFIG=~/.config/starship/starship.toml

# History
source "${HOME}/.config/zsh/history.zsh"

# FZF
export FZF_DEFAULT_COMMAND='rg --files --hidden -g "!.git" '

# Zoxide
eval "$(zoxide init zsh)"

# N - Node Version Manager
export N_PREFIX="${HOME}/.n"
export PATH="${HOME}/.n/bin:${PATH}"

# Cargo
export PATH="${HOME}/.cargo/bin:${PATH}"

# Add node_modules/.bin to path.
function _node_bin() {
  path=( ${path[@]:#*node_modules*} )
  local p="$(pwd)"
  while [[ "$p" != '/' ]]; do
    if [[ -d "$p/node_modules/.bin" ]]; then
      path+=("$p/node_modules/.bin")
    fi
    p="$(dirname "$p")"
  done
  typeset -U path
}

precmd_functions+=(_node_bin)

# Go
export PATH="$PATH:$(go env GOBIN):$(go env GOPATH)/bin"
