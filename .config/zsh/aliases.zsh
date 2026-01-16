alias n=nvim
alias node-n='command n'

if command -v yay >/dev/null 2>&1; then
  alias yaas="yay -S --noconfirm"
  alias yaasu="sudo pacman -Suy --noconfirm && yay -Suy --noconfirm"
  alias yaac="yay -Rscnd $(yay -Qdtq | xargs)"
fi

alias json-schema="jq --argjson nullable true 'include \"schema\"; schema'"

