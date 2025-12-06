# Dotfiles

## Usage

`.stowrc` file in this repository includes the target set to home folder,, so we can place this repository anywhere in our computer, just run `stow` commands inside this repository path so the `.stowrc` is applied. If not we simply add the target manually with `stow -t ~ nvim`.


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
