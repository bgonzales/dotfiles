return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"wojciech-kulik/xcodebuild.nvim",
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio", -- Required by nvim-dap-ui
			"theHamsta/nvim-dap-virtual-text", -- Optional: Show variable values inline
		},
		config = function()
			local dap = require("dap")
			local xcodebuild = require("xcodebuild.integrations.dap")

			-- Setup xcodebuild integration (handles codelldb automatically for Xcode 16+)
			xcodebuild.setup()

			-- Customize breakpoint signs to look like Xcode
			vim.fn.sign_define("DapBreakpoint", {
				text = "●",
				texthl = "DapBreakpoint",
				linehl = "",
				numhl = "",
			})
			vim.fn.sign_define("DapBreakpointCondition", {
				text = "◆",
				texthl = "DapBreakpointCondition",
				linehl = "",
				numhl = "",
			})
			vim.fn.sign_define("DapLogPoint", {
				text = "◆",
				texthl = "DapLogPoint",
				linehl = "",
				numhl = "",
			})
			vim.fn.sign_define("DapStopped", {
				text = "▶",
				texthl = "DapStopped",
				linehl = "DapStoppedLine",
				numhl = "",
			})
			vim.fn.sign_define("DapBreakpointRejected", {
				text = "○",
				texthl = "DapBreakpointRejected",
				linehl = "",
				numhl = "",
			})

			-- Setup nvim-dap-ui
			local dapui = require("dapui")
			dapui.setup({
				controls = {
					element = "repl",
					enabled = true,
				},
				layouts = {
					{
						elements = {
							{ id = "scopes", size = 0.25 },
							{ id = "breakpoints", size = 0.25 },
							{ id = "stacks", size = 0.25 },
							{ id = "watches", size = 0.25 },
						},
						position = "left",
						size = 40,
					},
					{
						elements = {
							{ id = "repl", size = 0.5 },
							{ id = "console", size = 0.5 }, -- CRITICAL: Shows simulator logs
						},
						position = "bottom",
						size = 10,
					},
				},
			})

			-- Setup virtual text for variable values
			require("nvim-dap-virtual-text").setup({
				enabled = true,
				enabled_commands = true,
				highlight_changed_variables = true,
			})

			-- Auto-open/close dap-ui
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end
		end,
		keys = {
			-- Debug lifecycle
			{
				"<leader>xd",
				function()
					require("xcodebuild.integrations.dap").build_and_debug()
				end,
				desc = "Build & Debug",
			},
			{
				"<leader>xD",
				function()
					require("xcodebuild.integrations.dap").debug_without_build()
				end,
				desc = "Debug (no build)",
			},
			{ "<leader>xa", "<cmd>XcodebuildAttachDebugger<cr>", desc = "Attach Debugger" },

			-- Debug controls
			{
				"<leader>xdc",
				function()
					require("dap").continue()
				end,
				desc = "Continue/Start",
			},
			{
				"<leader>xdn",
				function()
					require("dap").step_over()
				end,
				desc = "Step Over",
			},
			{
				"<leader>xdi",
				function()
					require("dap").step_into()
				end,
				desc = "Step Into",
			},
			{
				"<leader>xdo",
				function()
					require("dap").step_out()
				end,
				desc = "Step Out",
			},
			{
				"<leader>xdq",
				function()
					require("dap").terminate()
				end,
				desc = "Terminate",
			},

			-- Breakpoints
			{
				"<leader>xdb",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Toggle Breakpoint",
			},
			{
				"<leader>xdB",
				function()
					require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
				end,
				desc = "Conditional Breakpoint",
			},
			{
				"<leader>xdl",
				function()
					require("dap").set_breakpoint(nil, nil, vim.fn.input("Log message: "))
				end,
				desc = "Log Point",
			},

			-- UI
			{
				"<leader>xdu",
				function()
					require("dapui").toggle()
				end,
				desc = "Toggle Debug UI",
			},
			{
				"<leader>xde",
				function()
					require("dapui").eval()
				end,
				desc = "Eval Expression",
				mode = { "n", "v" },
			},
		},
	},
}
