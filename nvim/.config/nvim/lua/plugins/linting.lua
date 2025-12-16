return {
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")

			lint.linters_by_ft = {
				swift = { "swiftlint" },
				lua = { "selene" },
				markdown = { "markdownlint" },
				sh = { "shellcheck" },
				bash = { "shellcheck" },
				zsh = { "shellcheck" },
				dockerfile = { "hadolint" },
				go = { "golangci-lint" },
				css = { "stylelint" },
				scss = { "stylelint" },
				yaml = { "yamllint" },
				c = { "clangtidy", "cppcheck" },
				cpp = { "clangtidy", "cppcheck" },
				tex = { "chktex" },
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
