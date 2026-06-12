export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git z sudo extract)

source "$ZSH/oh-my-zsh.sh"

if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi

if [ -f "$HOME/.config/zsh/aliases.zsh" ]; then
    source "$HOME/.config/zsh/aliases.zsh"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f "$HOME/.p10k.zsh" ]] || source "$HOME/.p10k.zsh"
