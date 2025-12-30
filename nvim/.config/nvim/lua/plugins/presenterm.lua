return {
	{
		"Piotr1215/presenterm.nvim",
		opts = {
			-- Enable default keybindings for navigation
			default_keybindings = true,
			-- Preview settings
			preview = {
				-- Safe mode by default (code displays but doesn't execute)
				-- Change to "presenterm -xX" if you need code execution for demos
				command = "presenterm",
				-- Sync navigation between markdown and preview
				presentation_preview_sync = true,
			},
			-- Faster startup (disable if you need full environment variables)
			login_shell = false,
		},
		config = function(_, opts)
			require("presenterm").setup(opts)

			-- Recommended keymaps using correct command format
			-- Preview in split
			vim.keymap.set("n", "<leader>pp", ":Presenterm preview<CR>", { desc = "Toggle presentation preview" })

			-- Fullscreen presentation in new terminal (macOS)
			vim.keymap.set("n", "<leader>pf", function()
				local file = vim.fn.expand("%:p")
				-- Using osascript to open in new Terminal window
				local cmd = string.format(
					"osascript -e 'tell application \"Terminal\" to do script \"presenterm -p %s\"'",
					vim.fn.shellescape(file)
				)
				vim.fn.system(cmd)
			end, { desc = "Present fullscreen in terminal" })

			-- Navigation
			vim.keymap.set("n", "<leader>pn", ":Presenterm next<CR>", { desc = "Next slide" })
			vim.keymap.set("n", "<leader>pb", ":Presenterm prev<CR>", { desc = "Previous slide" })
			vim.keymap.set("n", "<leader>pl", ":Presenterm list<CR>", { desc = "List all slides" })

			-- Slide management
			vim.keymap.set("n", "<leader>pc", ":Presenterm new<CR>", { desc = "Create new slide" })
			vim.keymap.set("n", "<leader>pd", ":Presenterm delete<CR>", { desc = "Delete slide" })
			vim.keymap.set("n", "<leader>ps", ":Presenterm split<CR>", { desc = "Split slide at cursor" })
			vim.keymap.set("n", "<leader>py", ":Presenterm yank<CR>", { desc = "Yank current slide" })
			vim.keymap.set("n", "<leader>pm", ":Presenterm reorder<CR>", { desc = "Reorder slides" })
			vim.keymap.set("n", "<leader>pt", ":Presenterm toggle-sync<CR>", { desc = "Toggle sync" })
		end,
	},
}
