# Basic completion setup
autoload -Uz compinit
compinit

# Aliases
source "${HOME}/.config/zsh/aliases.zsh"

# Starship Prompt
eval "$(starship init zsh)"
if [[ -f "${HOME}/.config/starship/starship.toml" ]]; then
  export STARSHIP_CONFIG="${HOME}/.config/starship/starship.toml"
elif [[ -f "${HOME}/.config/starship.toml" ]]; then
  export STARSHIP_CONFIG="${HOME}/.config/starship.toml"
fi

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
export GOPATH=$HOME/go

# My Stuff
export PATH="${HOME}/.local/share/bin:${PATH}"

# ngrok auth
if [[ -f "${HOME}/.config/op/plugins.sh" ]]; then
  source "${HOME}/.config/op/plugins.sh"
fi
