EDITOR=/usr/bin/nvim

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/fzf/key-bindings.zsh

export SSH_AUTH_SOCK="${HOME}/.1password/agent.sock"
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/docker.sock

alias shutdown="systemctl poweroff"
alias reboot="systemctl reboot"

