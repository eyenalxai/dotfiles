alias n=nvim
alias node-n='command n'

alias yaas="yay -S"
alias yaasu="sudo pacman -Suy --noconfirm && yay -Suy"
alias yaac="yay -Rscnd $(yay -Qdtq | xargs)"

alias json-schema="jq --argjson nullable true 'include \"schema\"; schema'"

