return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		version = false,
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
		opts = {
			ensure_installed = {
				"bash", "c", "cpp",
				"css", "javascript", "html", "typescript", "tsx",
				"svelte",
				"swift", "python", "kotlin", "latex",
				"lua", "luadoc", "luap",
				"markdown", "markdown_inline", "json",
				"vim", "vimdoc",
				"yaml",
			},
		},
		config = function(_, opts)
			require("nvim-treesitter").setup()

			-- Install parsers (new API uses .install() instead of ensure_installed)
			if opts.ensure_installed and #opts.ensure_installed > 0 then
				local installed = require("nvim-treesitter").get_installed()
				local installed_set = {}
				for _, lang in ipairs(installed) do
					installed_set[lang] = true
				end

				local to_install = vim.tbl_filter(function(lang)
					return not installed_set[lang]
				end, opts.ensure_installed)

				if #to_install > 0 then
					require("nvim-treesitter").install(to_install)
				end
			end
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		event = "VeryLazy",
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = function()
			-- Setup options (new API)
			require("nvim-treesitter-textobjects").setup({
				select = { lookahead = true },
				move = { set_jumps = true },
			})

			local select = require("nvim-treesitter-textobjects.select")
			local move = require("nvim-treesitter-textobjects.move")
			local swap = require("nvim-treesitter-textobjects.swap")

			-- Select keymaps
			local select_keymaps = {
				["af"] = "@function.outer",
				["if"] = "@function.inner",
				["ac"] = "@class.outer",
				["ic"] = "@class.inner",
				["aa"] = "@parameter.outer",
				["ia"] = "@parameter.inner",
			}
			for key, query in pairs(select_keymaps) do
				vim.keymap.set({ "x", "o" }, key, function()
					select.select_textobject(query, "textobjects")
				end, { desc = "Select " .. query })
			end

			-- Move keymaps
			local move_keymaps = {
				["]f"] = { move.goto_next_start, "@function.outer" },
				["]c"] = { move.goto_next_start, "@class.outer" },
				["]a"] = { move.goto_next_start, "@parameter.inner" },
				["]F"] = { move.goto_next_end, "@function.outer" },
				["]C"] = { move.goto_next_end, "@class.outer" },
				["[f"] = { move.goto_previous_start, "@function.outer" },
				["[c"] = { move.goto_previous_start, "@class.outer" },
				["[a"] = { move.goto_previous_start, "@parameter.inner" },
				["[F"] = { move.goto_previous_end, "@function.outer" },
				["[C"] = { move.goto_previous_end, "@class.outer" },
			}
			for key, config in pairs(move_keymaps) do
				vim.keymap.set({ "n", "x", "o" }, key, function()
					config[1](config[2], "textobjects")
				end, { desc = "Move to " .. config[2] })
			end

			-- Swap keymaps
			vim.keymap.set("n", "<leader>a", function()
				swap.swap_next("@parameter.inner")
			end, { desc = "Swap next parameter" })
			vim.keymap.set("n", "<leader>A", function()
				swap.swap_previous("@parameter.inner")
			end, { desc = "Swap previous parameter" })
		end,
	},
}
