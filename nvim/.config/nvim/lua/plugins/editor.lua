return {
	{ "nvim-lua/plenary.nvim", lazy = true },
	{ "nvim-tree/nvim-web-devicons", lazy = true },
	{
		"nvim-pack/nvim-spectre",
		cmd = "Spectre",
		opts = { open_cmd = "noswapfile vnew" },
		keys = {
			{ "<leader>sr", '<CMD>lua require("spectre").toggle()<CR>', desc = "Replace in files (Spectre)" },
		},
	},
	{
		"nvim-telescope/telescope.nvim",
		lazy = false,
		dependencies = {
			{ "nvim-lua/plenary.nvim" },
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				config = function()
					require("telescope").load_extension("fzf")
				end
			}, {
				"nvim-telescope/telescope-file-browser.nvim",
				config = function()
					require("telescope").load_extension("file_browser")
				end
			}
		},
		opts = {
			defaults = {
				sorting_strategy = "ascending",
				layout_config = {
					prompt_position = "top",
					horizontal = {
						preview_width = 0.5,
					},
					vertical = {
						preview_height = 0.5,
					},
				},
				extensions = {
					file_browser = { },
				},
			},
		},
		keys = {
			{
				"<leader>o",
				function()
					require("telescope.builtin").find_files({hidden=true})
				end,
				desc = "Find Plugin File",
			},
			{ "<leader>co", "<CMD>Telescope find_files cwd=%:p:h<CR>", desc = "Find in [C]urrent folder"},
			{ "<leader>sf", "<CMD>Telescope current_buffer_fuzzy_find<CR>", desc = "Fuzzily [S]earch in current [F]ile" },
			{ "<leader>saf", "<CMD>Telescope live_grep<CR>", desc = "[S]earch in [A]ll [F]iles" },
			{ '<leader>gs', "<CMD>Telescope git_status<CR>", desc = '[G]it [S]tatus' },
			{ "<leader>fb", "<CMD>Telescope file_browser prompt_path=true no_ignore=true<CR>", desc = "Open [F]ile [B]rowser" },
			{ "<leader>fc", "<CMD>Telescope file_browser path=%:p:h select_buffer=true no_ignore=true<CR>", desc = "Open [F]ile browser in [C]urrent directory"},
			{ "<leader>sd", "<CMD>Telescope diagnostics<CR>", desc = "[S]earch [D]iagnostics"},
		},
	},
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signcolumn = true,
			numhl = false,
			linehl = false,
			word_diff = false,
			current_line_blame = false,
			current_line_blame_opts = {
				virt_text = true,
				virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
				delay = 50,
				ignore_whitespace = false,
			},
			current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
			on_attach = function(buffer)
				local gs = package.loaded.gitsigns

				local function map(mode, l, r, desc)
					vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
				end

				map("n", "<C-ç>", gs.next_hunk, "Jump to next git change")
				map("n", "<C-Ç>", gs.prev_hunk, "Jump to prev git change")
				map("n", "<leader>gg", gs.preview_hunk, "Preview hunk")
				map("n", "<leader>gb", "<CMD>Gitsigns toggle_current_line_blame<CR>", "[G]it [B]lame")
				map("n", "<leader>gd", gs.diffthis, "[G]it [D]iff")
			end,
		},
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts_extend = { "spec" },
		opts = {
			plugins = { spelling = true },
			defaults = {},
			spec = {
				{
					mode = { "n", "v" },
					{ "<leader><tab>", group = "tabs" },
					{ "<leader>b", group = "buffer" },
					{ "<leader>e", group = "code" },
					{ "<leader>f", group = "file/find" },
					{ "<leader>g", group = "git" },
					{ "<leader>gh", group = "hunks" },
					{ "<leader>q", group = "quit/session" },
					{ "<leader>s", group = "search" },
					{ "<leader>u", group = "ui" },
					{ "<leader>w", group = "windows" },
					{ "<leader>x", group = "diagnostics/quickfix" },
					{ "[", group = "prev" },
					{ "]", group = "next" },
					{ "g", group = "goto" },
					{ "gz", group = "surround" },
				}
			},
		},
		config = function(_, opts)
			local wk = require("which-key")
			wk.setup(opts)
			if not vim.tbl_isempty(opts.defaults) then
				wk.register(opts.defaults)
			end
		end,
	},
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		cmd = { "TodoTelescope" },
		event = { "BufReadPost", "BufNewFile" },
		config = true,
		keys = {
			{ "<leader>ft", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME,NOTE,WARNING<cr>", desc = "[F]ind [T]o do" },
		},
	},
	-- Comments
	{ "JoosepAlviste/nvim-ts-context-commentstring", lazy = true },
	{
		"echasnovski/mini.comment",
		event = "VeryLazy",
		opts = {
			options = {
				custom_commentstring = function()
					return require("ts_context_commentstring.internal").calculate_commentstring() or vim.bo.commentstring
				end,
			},
		},
	},
	-- Auto pairs
	{
		"echasnovski/mini.pairs",
		event = "VeryLazy",
		opts = {},
	},
	{
		"windwp/nvim-ts-autotag",
		event = "InsertEnter",
		opts = {
			-- Temporal fix for wrong self closing tags: https://github.com/windwp/nvim-ts-autotag/issues/124
			enable_close_on_slash = false
		},
	},
	{
		"bgonzales/markdown-todo.nvim",
		ft = "markdown",
		opts = {},
	},
}
