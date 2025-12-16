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
				},
				-- Enhanced test configuration
				marks = {
					show_signs = true,
					show_diagnostics = true,
				},
				test_search = {
					file_matching = "lsp_filename",
					lsp_client = "sourcekit",
					lsp_timeout = 200,
				},
				-- Device management
				focus_simulator_on_app_launch = true,
			})
		end,
		keys = {
			-- Editor actions
			{ "<leader>xc", "<CMD>XcodebuildPicker<CR>", desc = "Show Xcodebuild Actions" },
			{ "<leader>xb", "<CMD>XcodebuildBuild<CR>", desc = "Build project" },
			{ "<leader>xr", "<CMD>XcodebuildBuildRun<CR>", desc = "Build and run project" },
			{ "<leader>xs", "<CMD>XcodebuildBuildCancel<CR>", desc = "Stop running action" },
			{ "<leader>xl", "<CMD>XcodebuildToggleLogs<CR>", desc = "Toggle logs" },

			-- Testing
			{ "<leader>xt", "<CMD>XcodebuildTest<CR>", desc = "Run all tests" },
			{ "<leader>xT", "<CMD>XcodebuildTestClass<CR>", desc = "Run test class" },
			{ "<leader>x.", "<CMD>XcodebuildTestNearest<CR>", desc = "Run nearest test" },
			{ "<leader>xf", "<CMD>XcodebuildTestFailing<CR>", desc = "Run failing tests" },
			{ "<leader>xR", "<CMD>XcodebuildTestRepeat<CR>", desc = "Repeat last test" },
			{ "<leader>xv", "<CMD>XcodebuildTestSelected<CR>", desc = "Run selected tests", mode = "v" },

			-- Device/Simulator
			{ "<leader>xS", "<CMD>XcodebuildSelectDevice<CR>", desc = "Select device/simulator" },
			{ "<leader>xn", "<CMD>XcodebuildNextDevice<CR>", desc = "Next device" },
			{ "<leader>xp", "<CMD>XcodebuildPreviousDevice<CR>", desc = "Previous device" },
			{ "<leader>xB", "<CMD>XcodebuildBootSimulator<CR>", desc = "Boot simulator" },

			-- Test Explorer & Coverage
			{ "<leader>xe", "<CMD>XcodebuildTestExplorerToggle<CR>", desc = "Toggle test explorer" },
			{ "<leader>xC", "<CMD>XcodebuildToggleCodeCoverage<CR>", desc = "Toggle code coverage" },
		}
	},
}
