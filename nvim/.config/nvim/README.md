# Neovim configuration

## Requirements

- Requirements for Telescope and language servers: `brew install fzf ripgrep fd node luarocks`
- Treesitter-cli: `npm install -g tree-sitter-cli` (latest version, 0.26.x+)
- Requirements for Xcode plugin: `brew install xcode-build-server xcbeautify swiftformat swiftlint` and `gem install xcodeproj --user-install` (make sure to include .gems in PATH)

`xcode-build-server` is optional

### Tree-sitter Configuration

This config uses `branch = "main"` for nvim-treesitter and nvim-treesitter-textobjects with the new API:
- `require("nvim-treesitter").setup(opts)` (new API)
- Textobjects configured as a separate plugin

**Required version: tree-sitter-cli 0.26.x+** (tested with 0.26.3)

## Check Health

- Run `:checkhealth`
- If throwing error related to tree-sitter CLI not found: `npm install -g tree-sitter-cli`

## Installation

### Clean Install

Clear all Neovim data and cache:

```bash
rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim ~/.config/nvim/lazy-lock.json && nvim
```

### Updating from Old Config (master branch + tree-sitter 0.25.x)

If you have a machine running the old configuration (using `branch = "master"` and tree-sitter 0.25.x), follow these steps:

Update tree-sitter-cli:
```bash
npm uninstall -g tree-sitter-cli
npm install -g tree-sitter-cli
```

Clean install Neovim plugins:
```bash
rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim ~/.config/nvim/lazy-lock.json && nvim
```

No need to reinstall Neovim itself - just update tree-sitter-cli and clear the plugin data.

## Language Support

Complete development environment with LSP, formatting, linting, and completion for 25+ languages.

| Language | LSP | Completion | Formatter | Linter |
|----------|-----|------------|-----------|--------|
| **Swift** | ✅ sourcekit-lsp | ✅ blink.cmp | ✅ swiftformat | ✅ swiftlint |
| **C** | ✅ clangd + sourcekit | ✅ blink.cmp | ✅ clang-format | ⚠️ via LSP (clangd) |
| **C++** | ✅ clangd + sourcekit | ✅ blink.cmp | ✅ clang-format | ⚠️ via LSP (clangd) |
| **Objective-C** | ✅ sourcekit-lsp | ✅ blink.cmp | ✅ clang-format | ⚠️ via LSP |
| **Objective-C++** | ✅ sourcekit-lsp | ✅ blink.cmp | ✅ clang-format | ⚠️ via LSP |
| **Python** | ✅ pyright + ruff | ✅ blink.cmp | ✅ ruff_format | ⚠️ via LSP (ruff) |
| **Go** | ❌ (requires Go) | ❌ | ❌ | ❌ |
| **Rust** | ✅ rust_analyzer | ✅ blink.cmp | ✅ rustfmt | ✅ clippy (via LSP) |
| **Lua** | ✅ lua_ls | ✅ blink.cmp | ✅ stylua | ⚠️ via LSP (lua_ls) |
| **LaTeX** | ✅ texlab | ✅ blink.cmp | ✅ latexindent | ⚠️ via LSP (texlab) |
| **JavaScript** | ✅ ts_ls + eslint | ✅ blink.cmp | ✅ prettier | ⚠️ via LSP (eslint) |
| **TypeScript** | ✅ ts_ls + eslint | ✅ blink.cmp | ✅ prettier | ⚠️ via LSP (eslint) |
| **JSX** | ✅ ts_ls + eslint | ✅ blink.cmp | ✅ prettier | ⚠️ via LSP (eslint) |
| **TSX** | ✅ ts_ls + eslint | ✅ blink.cmp | ✅ prettier | ⚠️ via LSP (eslint) |
| **Svelte** | ✅ svelte + eslint | ✅ blink.cmp | ✅ prettier | ⚠️ via LSP (eslint) |
| **Markdown** | ✅ marksman | ✅ blink.cmp | ✅ prettier | ✅ markdownlint |
| **CSS** | ✅ cssls | ✅ blink.cmp | ✅ prettier | ✅ stylelint |
| **SCSS** | ⚠️ via cssls | ✅ blink.cmp | ✅ prettier | ✅ stylelint |
| **HTML** | ✅ html | ✅ blink.cmp | ✅ prettier | ⚠️ via LSP |
| **JSON** | ✅ jsonls | ✅ blink.cmp | ✅ prettier | ⚠️ via LSP |
| **JSONC** | ✅ jsonls | ✅ blink.cmp | ✅ prettier | ⚠️ via LSP |
| **YAML** | ❌ | ❌ | ✅ prettier | ✅ yamllint |
| **Tailwind CSS** | ✅ tailwindcss | ✅ blink.cmp | ⚠️ via LSP | ❌ |
| **Dockerfile** | ✅ dockerls | ✅ blink.cmp | ⚠️ via LSP | ✅ hadolint |
| **Docker Compose** | ✅ docker_compose_ls | ✅ blink.cmp | ⚠️ via LSP | ⚠️ via LSP |
| **Shell (sh/bash/zsh)** | ❌ | ❌ | ❌ | ✅ shellcheck |

**Legend:** ✅ Full support | ⚠️ Partial/LSP fallback | ❌ Not configured

### Summary
- **25+ languages** supported with LSP, formatting, and/or linting
- **6 languages** with dedicated linters (Swift, Rust, Markdown, CSS/SCSS, Dockerfile, Shell, YAML)
- **9 languages** use LSP diagnostics only (Lua, Python, JS/TS, C/C++, LaTeX, etc.)
- **24 tools** auto-installed via Mason (swiftformat + swiftlint via Homebrew)
- **All formatters** use conform.nvim with LSP fallback
- **Dedicated linters** use nvim-lint, **LSP-based** use built-in diagnostics

### Key Keybindings
- `,ff` - Format current file (all languages)
- `,cl` - Trigger linting (all languages)
- `,xd` - Build & debug (Swift/Xcode)
- `,xt` - Run tests (Swift/Xcode)
