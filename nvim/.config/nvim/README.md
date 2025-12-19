# Neovim configuration

## Requirements

- Requirements for Telescope and language servers: `brew install fzf ripgrep fd node luarocks`
- Treesitter-cli: `npm install -g tree-sitter-cli@0.25.9` (version 0.25.x required, see note below)
- Requirements for Xcode plugin: `brew install xcode-build-server xcbeautify swiftformat swiftlint` and `gem install xcodeproj --user-install` (make sure to include .gems in PATH)

`xcode-build-server` is optional

### Tree-sitter Version Note

This config uses `branch = "master"` for nvim-treesitter and nvim-treesitter-textobjects because:
- The `main` branch removed `nvim-treesitter.configs` module (breaking change)
- tree-sitter-cli 0.26.x removed the `--no-bindings` flag
- tree-sitter-cli 0.24.x doesn't support ABI version 15 (needed for swift parser)

**Required version: tree-sitter-cli 0.25.x** (tested with 0.25.9)

## Check Health

- Run `:checkhealth`
- If throwing error related to tree-sitter CLI not found: `npm install -g tree-sitter-cli@0.25.9`

## Installation

Clear configuration if needed

```bash
rm -rf ~/.cache/nvim ~/.local/share/nvim
rm lazy-lock.json
```

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

## TODO

- [ ] Update nvim-treesitter config to use `main` branch and new API (`require("nvim-treesitter").setup()`) once nvim-treesitter-textobjects is updated for compatibility
- [ ] Update tree-sitter-cli to latest version (0.26.x+) once nvim-treesitter supports it
