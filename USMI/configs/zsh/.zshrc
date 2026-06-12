# ── USMI Zsh Configuration ──

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)

source "$ZSH/oh-my-zsh.sh"

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

if command -v fastfetch &>/dev/null; then
    fastfetch
fi

if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi

if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

if command -v fzf &>/dev/null; then
    source /usr/share/fzf/completion.zsh 2>/dev/null || true
    source /usr/share/fzf/key-bindings.zsh 2>/dev/null || true
fi

alias ls='eza --icons'
alias ll='eza -la --icons'
alias lt='eza -T --icons'
alias cat='bat'
alias grep='rg'
alias top='btop'
alias ..='cd ..'
alias ...='cd ../..'
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph'
