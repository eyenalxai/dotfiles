EDITOR=/usr/bin/nvim

source_if_exists() {
  [[ -f "$1" ]] && source "$1"
}

case "$(uname -s)" in
  Darwin)
    source_if_exists /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source_if_exists /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    source_if_exists /opt/homebrew/opt/fzf/shell/key-bindings.zsh
    ;;
  Linux)
    source_if_exists /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    source_if_exists /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    source_if_exists /usr/share/fzf/key-bindings.zsh
    ;;
esac

export SSH_AUTH_SOCK="${HOME}/.1password/agent.sock"

if [[ "$(uname -s)" == "Linux" ]]; then
  export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
  alias shutdown="systemctl poweroff"
  alias reboot="systemctl reboot"
fi

