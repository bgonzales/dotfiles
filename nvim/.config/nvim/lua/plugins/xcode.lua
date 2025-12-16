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

			-- Custom command to generate buildServer.json from xcodebuild config
			vim.api.nvim_create_user_command("XcodebuildGenerateBuildServer", function()
				local config = require("xcodebuild.project.config").settings

				if not config.scheme then
					vim.notify("No scheme configured. Run :XcodebuildSetup first", vim.log.levels.ERROR)
					return
				end

				local project_file = config.projectFile or config.workspace
				if not project_file then
					vim.notify("No project/workspace found", vim.log.levels.ERROR)
					return
				end

				local is_workspace = project_file:match("%.xcworkspace$")
				local flag = is_workspace and "-workspace" or "-project"

				local cmd = string.format(
					"xcode-build-server config %s %s -scheme %s",
					flag,
					vim.fn.shellescape(project_file),
					vim.fn.shellescape(config.scheme)
				)

				vim.notify("Generating buildServer.json...", vim.log.levels.INFO)
				vim.fn.jobstart(cmd, {
					on_exit = function(_, exit_code)
						if exit_code == 0 then
							vim.notify("✓ buildServer.json generated successfully", vim.log.levels.INFO)
							vim.cmd("LspRestart sourcekit")
						else
							vim.notify("✗ Failed to generate buildServer.json", vim.log.levels.ERROR)
						end
					end
				})
			end, { desc = "Generate buildServer.json from xcodebuild config" })
		end,
		keys = {
			-- Editor actions
			{ "<leader>xc", "<CMD>XcodebuildPicker<CR>", desc = "Show Xcodebuild Actions" },
			{ "<leader>xb", "<CMD>XcodebuildBuild<CR>", desc = "Build project" },
			{ "<leader>xr", "<CMD>XcodebuildBuildRun<CR>", desc = "Build and run project" },
			{ "<leader>xs", "<CMD>XcodebuildBuildCancel<CR>", desc = "Stop running action" },
			{ "<leader>xl", "<CMD>XcodebuildToggleLogs<CR>", desc = "Toggle logs" },
			{ "<leader>xg", "<CMD>XcodebuildGenerateBuildServer<CR>", desc = "Generate buildServer.json" },

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
