# Zsh Shared Configuration

Shared zsh configuration for use across machines with GNU Stow.

## Installation

1. Install dependencies:

```bash
brew install zsh-autosuggestions zsh-completions starship
```

2. Stow the package:

```bash
cd ~/Developer/dotfiles
stow zsh
```

3. Add the following to your local `~/.zshrc`:

```bash
# ─────────────────────────────────────────────────────────────────────────────────
# Machine-specific Configuration
# ─────────────────────────────────────────────────────────────────────────────────
# Add your machine-specific PATH exports here, for example:
# export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"

# ─────────────────────────────────────────────────────────────────────────────────
# Shared Configuration (from dotfiles)
# ─────────────────────────────────────────────────────────────────────────────────
# shellcheck disable=SC1091
[[ -f "$HOME/.config/zsh/shared.zsh" ]] && source "$HOME/.config/zsh/shared.zsh"
```

## What's Included

- **zsh-completions**: Tab completions for 200+ commands
- **zsh-autosuggestions**: Ghost text suggestions from history (press → to accept)
- **Starship prompt**: Cross-shell prompt with git integration

The shared config auto-detects Homebrew location (Intel vs Apple Silicon).
