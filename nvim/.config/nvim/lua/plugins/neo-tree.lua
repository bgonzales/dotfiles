return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	cmd = "Neotree",
	keys = {
		{ "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle file tree" },
		{ "<leader>E", "<cmd>Neotree reveal<cr>", desc = "Reveal file in tree" },
		{ "<leader>ge", "<cmd>Neotree git_status<cr>", desc = "Git status tree" },
	},
	deactivate = function()
		vim.cmd([[Neotree close]])
	end,
	opts = {
		close_if_last_window = true,
		popup_border_style = "rounded",
		enable_git_status = true,
		enable_diagnostics = true,
		event_handlers = {
			{
				event = "neo_tree_window_after_open",
				handler = function(args)
					if args.position == "left" or args.position == "right" then
						vim.cmd("wincmd =")
					end
				end,
			},
		},
		default_component_configs = {
			indent = {
				with_expanders = true,
				expander_collapsed = "",
				expander_expanded = "",
			},
			git_status = {
				symbols = {
					added = "",
					modified = "",
					deleted = "",
					renamed = "",
					untracked = "",
					ignored = "",
					unstaged = "",
					staged = "",
					conflict = "",
				},
			},
		},
		filesystem = {
			follow_current_file = {
				enabled = true,
				leave_dirs_open = true, -- Keep directories open when switching files
			},
			use_libuv_file_watcher = true,
			hijack_netrw_behavior = "disabled", -- Prevents conflict with disabled netrw
			filtered_items = {
				visible = false,
				hide_dotfiles = false,
				hide_gitignored = false,
				hide_by_name = {
					".git",
					".DS_Store",
				},
			},
		},
		window = {
			position = "left",
			width = 35,
			mappings = {
				["<space>"] = "none", -- Disable space to avoid conflicts with leader
				["l"] = "open",
				["h"] = "close_node",
				["<cr>"] = "open",
				["v"] = "open_vsplit",
				["s"] = "open_split",
				["t"] = "open_tabnew",
				["P"] = { "toggle_preview", config = { use_float = true } },
				["a"] = { "add", config = { show_path = "relative" } },
				["d"] = "delete",
				["r"] = "rename",
				["y"] = "copy_to_clipboard",
				["x"] = "cut_to_clipboard",
				["p"] = "paste_from_clipboard",
				["c"] = "copy",
				["m"] = "move",
				["q"] = "close_window",
				["R"] = "refresh",
				["?"] = "show_help",
			},
		},
		buffers = {
			follow_current_file = { enabled = true },
		},
		git_status = {
			window = {
				position = "float",
			},
		},
	},
}
