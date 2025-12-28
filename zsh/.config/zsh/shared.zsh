# ─────────────────────────────────────────────────────────────────────────────────
# Shared Zsh Configuration
# ─────────────────────────────────────────────────────────────────────────────────

# Detect Homebrew prefix (Intel: /usr/local, Apple Silicon: /opt/homebrew)
if [[ -d "/opt/homebrew" ]]; then
    BREW_PREFIX="/opt/homebrew"
else
    BREW_PREFIX="/usr/local"
fi

# ─────────────────────────────────────────────────────────────────────────────────
# Zsh Plugins
# Install: brew install zsh-autosuggestions zsh-completions
# Fix insecure directories warning: compaudit | xargs chmod g-w
# ─────────────────────────────────────────────────────────────────────────────────

# zsh-completions (extra tab completions for 200+ commands)
FPATH="$BREW_PREFIX/share/zsh-completions:$FPATH"
autoload -Uz compinit
compinit

# zsh-autosuggestions (ghost text suggestions from history, press → to accept)
[[ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
    source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# ─────────────────────────────────────────────────────────────────────────────────
# Starship Prompt
# ─────────────────────────────────────────────────────────────────────────────────
eval "$(starship init zsh)"
