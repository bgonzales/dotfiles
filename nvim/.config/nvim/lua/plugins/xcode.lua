return {
	{
		"wojciech-kulik/xcodebuild.nvim",
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"MunifTanjim/nui.nvim",
			-- "nvim-tree/nvim-tree.lua", -- (optional) to manage project files
			-- "stevearc/oil.nvim",       -- (optional) to manage project files
			"nvim-treesitter/nvim-treesitter", -- (optional) for Quick tests support (required Swift parser)
		},
		config = function()
			require("xcodebuild").setup({
				commands = {
					extra_build_args = {
						"-parallelizeTargets",
						"-skipMacroValidation"
					}
				},
				logs = {
					auto_open_on_success_build = true,
					auto_open_on_failed_build = true,
					auto_close_on_app_launch = false,
					auto_close_on_success_build = false,
				},
				quickfix = {
					show_errors_on_quickfixlist = true,
					show_warnings_on_quickfixlist = true,
				}
			})
		end,
		keys = {
			{ "<leader>xc", "<CMD>XcodebuildPicker<CR>", desc = "Show Xcodebuild Actions"},
			{ "<leader>xb", "<CMD>XcodebuildBuild<CR>", desc = "Build project"},
			{ "<leader>xr", "<CMD>XcodebuildBuildRun<CR>", desc = "Build and run project"},
			{ "<leader>xs", "<CMD>XcodebuildBuildCancel<CR>", desc = "Stop running action"},
			{ "<leader>xl", "<CMD>XcodebuildToggleLogs<CR>", desc = "Toggle logs"},
		}
	}
}
