return {
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")

			lint.linters_by_ft = {
				swift = { "swiftlint" },
				-- python: Use ruff LSP for diagnostics (matches LazyVim approach)
				-- javascript/typescript/svelte: Use eslint LSP for diagnostics (matches LazyVim approach)
				-- lua: Use lua_ls (LSP) diagnostics instead of selene (matches LazyVim approach)
				markdown = { "markdownlint" },
				sh = { "shellcheck" },
				bash = { "shellcheck" },
				zsh = { "shellcheck" },
				dockerfile = { "hadolint" },
				-- go = { "golangci-lint" }, -- Requires Go installation
				css = { "stylelint" },
				scss = { "stylelint" },
				yaml = { "yamllint" },
				-- C/C++: clang-tidy integrated into clangd LSP (no separate linter needed)
				-- LaTeX: chktex not in Mason, texlab LSP provides diagnostics
			}

			-- Auto-lint on save and buffer enter
			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					require("lint").try_lint()
				end,
			})
		end,
		keys = {
			{
				"<leader>cl",
				function()
					require("lint").try_lint()
				end,
				desc = "Trigger linting",
			},
		},
	},
}
