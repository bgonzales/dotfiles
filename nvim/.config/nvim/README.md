# Neovim configuration

## Requirements

- Requirements for Telescope and language servers: `brew install fzf ripgrep fd node`
- Treesitter-cli: `npm install -g tree-sitter-cli`
- Requirements for Xcode plugin: `brew install xcode-build-server xcbeautify` and `gem install xcodeproj --user-install` (make sure to include .gems in PATH)

`xcode-build-server` is optional

## Check Health

- Run `:checkhealth`
- If throwing error related to tree-sitter CLI not found: `npm install tree-sitter-cli`
- If getting error about luarocks: `brew install luarocks` 

## Installation

Clear configuration if needed

```bash
rm -rf ~/.cache/nvim ~/.local/share/nvim
rm lazy-lock.json
```
