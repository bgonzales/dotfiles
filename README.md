# Dotfiles

## Usage

### Stow all packages
```bash
stow */
```

### Stow individual packages
```bash
stow nvim
stow ghostty
```

### Unstow packages
```bash
stow -D nvim
stow -D ghostty
```

### Restow (useful after changes)
```bash
stow -R nvim
stow -R ghostty
```
