return {
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		opts = {
			formatters_by_ft = {
				swift = { "swiftformat" },
				lua = { "stylua" },
				python = { "ruff_format", "ruff_organize_imports" },
				-- go = { "gofmt", "goimports" }, -- Requires Go installation
				rust = { "rustfmt" },
				c = { "clang-format" },
				cpp = { "clang-format" },
				objc = { "clang-format" },
				objcpp = { "clang-format" },
				tex = { "latexindent" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				svelte = { "prettier" },
				html = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				json = { "prettier" },
				jsonc = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
			},
			-- format_on_save disabled - use manual formatting with ,ff instead
			-- Use LSP formatting as fallback if external formatter not available
			default_format_opts = {
				lsp_format = "fallback",
			},
			formatters = {
				swiftformat = {
					prepend_args = {
						"--indent", "4",
						"--maxwidth", "120",
						"--swiftversion", "5.9",
					},
				},
			},
		},
		-- Note: Format keybinding is defined in lua/config/lsp.lua as <leader>ff
		-- This works universally across all languages, not just Swift/Xcode
	},
}
