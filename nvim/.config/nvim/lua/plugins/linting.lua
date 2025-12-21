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

			-- Track linting state
			vim.g.linting_enabled = true

			-- Auto-lint on save and buffer enter
			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					if vim.g.linting_enabled then
						lint.try_lint()
					end
				end,
			})
		end,
		keys = {
			{
				"<leader>ll",
				function()
					local lint = require("lint")
					vim.g.linting_enabled = not vim.g.linting_enabled
					if vim.g.linting_enabled then
						lint.try_lint()
						vim.notify("Linting enabled", vim.log.levels.INFO)
					else
						-- Clear diagnostics for all configured linters
						local linters = lint.linters_by_ft[vim.bo.filetype] or {}
						for _, linter in ipairs(linters) do
							pcall(vim.diagnostic.reset, lint.get_namespace(linter))
						end
						vim.notify("Linting disabled", vim.log.levels.INFO)
					end
				end,
				desc = "Toggle [L]inting",
			},
		},
	},
}
