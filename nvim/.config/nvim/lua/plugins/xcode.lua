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
					auto_open_on_success_build = false,  -- Disabled: using notifications instead
					auto_open_on_failed_build = false,   -- Disabled: using Trouble instead
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

			-- Close Trouble when build starts (clear old errors)
			vim.api.nvim_create_autocmd("User", {
				pattern = "XcodebuildBuildStarted",
				callback = function()
					local trouble_ok, trouble = pcall(require, "trouble")
					if trouble_ok and trouble.is_open("qflist") then
						vim.cmd("Trouble qflist close")
					end
				end,
			})

			-- Auto-open Trouble on build failures
			vim.api.nvim_create_autocmd("User", {
				pattern = "XcodebuildBuildFinished",
				callback = function(event)
					local data = event.data
					-- Open Trouble if build failed with errors
					if not data.success and not data.cancelled and #data.errors > 0 then
						vim.cmd("Trouble qflist open")
						vim.cmd("echo 'Build Failed'")
					else
						vim.cmd("echo 'Build Succeeded'")
					end
				end,
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

			-- Error Navigation (Vim-style [ and ] prefix)
			{ "[e", "<CMD>cprevious<CR>", desc = "Previous build error" },
			{ "]e", "<CMD>cnext<CR>", desc = "Next build error" },
			{ "[E", "<CMD>cfirst<CR>", desc = "First build error" },
			{ "]E", "<CMD>clast<CR>", desc = "Last build error" },

			-- Quick access to error lists
			{ "<leader>xq", "<CMD>copen<CR>", desc = "Open quickfix list" },
		}
	},
}
