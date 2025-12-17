return {
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		opts = {
			auto_preview = false,  -- Disable automatic preview, only open on Enter
			modes = {
				diagnostics = {
					mode = "diagnostics",
					preview = {
						type = "split",
						relative = "win",
						position = "right",
						size = 0.3,
					},
				},
			},
		},
		config = function(_, opts)
			require("trouble").setup(opts)

			vim.api.nvim_create_autocmd("ColorScheme", {
				group = vim.api.nvim_create_augroup("TroubleCustomColors", { clear = true }),
				callback = function()
					-- Make Trouble window background match normal buffer background
					vim.api.nvim_set_hl(0, "TroubleNormal", { link = "Normal" })
					vim.api.nvim_set_hl(0, "TroubleNormalNC", { link = "Normal" })
				end,
			})

			-- Apply immediately for current colorscheme
			vim.api.nvim_set_hl(0, "TroubleNormal", { link = "Normal" })
			vim.api.nvim_set_hl(0, "TroubleNormalNC", { link = "Normal" })
		end,
		keys = {
			{
				"<leader>xx",
				"<cmd>Trouble diagnostics toggle<cr>",
				desc = "Diagnostics (Trouble)",
			},
			{
				"<leader>xX",
				"<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
				desc = "Buffer Diagnostics (Trouble)",
			},
			{
				"<leader>cs",
				"<cmd>Trouble symbols toggle focus=false<cr>",
				desc = "Symbols (Trouble)",
			},
			{
				"<leader>cD",
				"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
				desc = "LSP Definitions / references / ... (Trouble)",
			},
			{
				"<leader>xL",
				"<cmd>Trouble loclist toggle<cr>",
				desc = "Location List (Trouble)",
			},
			{
				"<leader>xQ",
				"<cmd>Trouble qflist toggle<cr>",
				desc = "Quickfix List (Trouble)",
			},
		},
	},
}
