EDITOR=/usr/bin/nvim

source_if_exists() {
  [[ -f "$1" ]] && source "$1"
}

case "$(uname -s)" in
  Darwin)
    source_if_exists /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source_if_exists /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    source_if_exists /opt/homebrew/opt/fzf/shell/key-bindings.zsh
    export COPYFILE_DISABLE=1
    export TAR_OPTIONS="--no-xattrs"
    ;;
  Linux)
    source_if_exists /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    source_if_exists /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    source_if_exists /usr/share/fzf/key-bindings.zsh
    ;;
esac

macos_1p_sock="${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
linux_1p_sock="${HOME}/.1password/agent.sock"

if [[ -S "$macos_1p_sock" ]]; then
  export SSH_AUTH_SOCK="$macos_1p_sock"
elif [[ -S "$linux_1p_sock" ]]; then
  export SSH_AUTH_SOCK="$linux_1p_sock"
fi

if [[ "$(uname -s)" == "Linux" ]]; then
  export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock
  alias shutdown="systemctl poweroff"
  alias reboot="systemctl reboot"
fi

