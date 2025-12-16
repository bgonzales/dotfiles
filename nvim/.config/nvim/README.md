# Neovim configuration

## Requirements

- Requirements for Telescope and language servers: `brew install fzf ripgrep fd node`
- Treesitter-cli: `npm install -g tree-sitter-cli`
- Requirements for Xcode plugin: `brew install xcode-build-server xcbeautify` and `gem install xcodeproj --user-install` (make sure to include .gems in PATH)
  - Note: swiftformat and swiftlint are auto-installed via Mason

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

## Language Support

Complete development environment with LSP, formatting, linting, and completion for 25+ languages.

| Language | LSP | Completion | Formatter | Linter |
|----------|-----|------------|-----------|--------|
| **Swift** | ✅ sourcekit-lsp | ✅ blink.cmp | ✅ swiftformat | ✅ swiftlint |
| **C** | ✅ clangd + sourcekit | ✅ blink.cmp | ✅ clang-format | ✅ clang-tidy + cppcheck |
| **C++** | ✅ clangd + sourcekit | ✅ blink.cmp | ✅ clang-format | ✅ clang-tidy + cppcheck |
| **Objective-C** | ✅ sourcekit-lsp | ✅ blink.cmp | ✅ clang-format | ⚠️ via LSP |
| **Objective-C++** | ✅ sourcekit-lsp | ✅ blink.cmp | ✅ clang-format | ⚠️ via LSP |
| **Python** | ✅ pyright + ruff | ✅ blink.cmp | ✅ ruff_format | ✅ ruff |
| **Go** | ✅ gopls | ✅ blink.cmp | ✅ gofmt + goimports | ✅ golangci-lint |
| **Rust** | ✅ rust_analyzer | ✅ blink.cmp | ✅ rustfmt | ✅ clippy (via LSP) |
| **Lua** | ✅ lua_ls | ✅ blink.cmp | ✅ stylua | ✅ selene |
| **LaTeX** | ✅ texlab | ✅ blink.cmp | ✅ latexindent | ✅ chktex |
| **JavaScript** | ✅ ts_ls + eslint | ✅ blink.cmp | ✅ prettier | ✅ eslint_d |
| **TypeScript** | ✅ ts_ls + eslint | ✅ blink.cmp | ✅ prettier | ✅ eslint_d |
| **JSX** | ✅ ts_ls + eslint | ✅ blink.cmp | ✅ prettier | ✅ eslint_d |
| **TSX** | ✅ ts_ls + eslint | ✅ blink.cmp | ✅ prettier | ✅ eslint_d |
| **Svelte** | ✅ svelte | ✅ blink.cmp | ✅ prettier | ✅ eslint_d |
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
- **16 languages** with full stack (LSP + Format + Lint + Completion)
- **33 tools** auto-installed via Mason
- **All formatters** use conform.nvim with LSP fallback
- **All linters** use nvim-lint with auto-linting on save

### Key Keybindings
- `,ff` - Format current file (all languages)
- `,cl` - Trigger linting (all languages)
- `,xd` - Build & debug (Swift/Xcode)
- `,xt` - Run tests (Swift/Xcode)
