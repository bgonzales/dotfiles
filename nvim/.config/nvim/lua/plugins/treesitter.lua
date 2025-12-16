return {
	'nvim-treesitter/nvim-treesitter',
	version = false,
	build = ":TSUpdate",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
	},
	cmd = { "TSUpdateSync" },
	keys = {
		{ "<c-space>", desc = "Increment selection" },
		{ "<bs>", desc = "Decrement selection", mode = "x" },
	},
	opts = {
		highlight = { enable = true },
		indent = { enable = true, disable = { 'python' } },
		ensure_installed = {
			'bash', 'c', 'cpp',
			'css', 'javascript', 'html', 'typescript', 'tsx',
			'svelte',
			'swift', 'python', 'kotlin', 'latex',
			'lua', 'luadoc', 'luap',
			'markdown', 'markdown_inline', 'json',
			'vim', "vimdoc",
			'yaml',
		},
		incremental_selection = {
			enable = true,
			keymaps = {
				init_selection = "<C-space>",
				node_incremental = "<C-space>",
				scope_incremental = false,
				node_decremental = "<bs>",
			},
		},
		textobjects = {
			select = {
				enable = true,
				lookahead = true,
				keymaps = {
					["af"] = { query = "@function.outer", desc = "a function" },
					["if"] = { query = "@function.inner", desc = "inner function" },
					["ac"] = { query = "@class.outer", desc = "a class" },
					["ic"] = { query = "@class.inner", desc = "inner class" },
					["aa"] = { query = "@parameter.outer", desc = "a argument" },
					["ia"] = { query = "@parameter.inner", desc = "inner argument" },
				},
			},
			move = {
				enable = true,
				goto_next_start = {
					["]f"] = { query = "@function.outer", desc = "Next function start" },
					["]c"] = { query = "@class.outer", desc = "Next class start" },
					["]a"] = { query = "@parameter.inner", desc = "Next argument" },
				},
				goto_next_end = {
					["]F"] = { query = "@function.outer", desc = "Next function end" },
					["]C"] = { query = "@class.outer", desc = "Next class end" },
				},
				goto_previous_start = {
					["[f"] = { query = "@function.outer", desc = "Previous function start" },
					["[c"] = { query = "@class.outer", desc = "Previous class start" },
					["[a"] = { query = "@parameter.inner", desc = "Previous argument" },
				},
				goto_previous_end = {
					["[F"] = { query = "@function.outer", desc = "Previous function end" },
					["[C"] = { query = "@class.outer", desc = "Previous class end" },
				},
			},
			swap = {
				enable = true,
				swap_next = {
					["<leader>a"] = { query = "@parameter.inner", desc = "Swap with next argument" },
				},
				swap_previous = {
					["<leader>A"] = { query = "@parameter.inner", desc = "Swap with previous argument" },
				},
			},
		},
	},
	config = function(_, opts)
		if type(opts.ensure_installed) == "table" then
			local added = {}
			opts.ensure_installed = vim.tbl_filter(function(lang)
				if added[lang] then
					return false
				end
				added[lang] = true
				return true
			end, opts.ensure_installed)
		end

		require("nvim-treesitter.configs").setup(opts)
	end
}
