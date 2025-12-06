return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	opts = function()
		local icons = require("config.icons").icons

		local function fg(name)
			return function()
				local hl = vim.api.nvim_get_hl(0, { name = name })
				return hl and hl.fg and { fg = string.format("#%06x", hl.fg) }
			end
		end

		return {
			options = {
				theme = "auto",
				globalstatus = true,
				disabled_filetypes = { statusline = { "dashboard", "alpha" } },
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch" },
				lualine_c = {
					{
						"diagnostics",
						symbols = {
							error = icons.diagnostics.Error,
							warn = icons.diagnostics.Warn,
							info = icons.diagnostics.Info,
							hint = icons.diagnostics.Hint,
						},
					},
					{ "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
					{ "filename", path = 1, symbols = { modified = icons.system.file, readonly = "", unnamed = "" } },
				},
				lualine_x = {
					{ require("lazy.status").updates, cond = require("lazy.status").has_updates, color = fg("Special") },
					{
						"diff",
						symbols = {
							added = icons.git.added,
							modified = icons.git.modified,
							removed = icons.git.removed,
						},
					},
				},
				lualine_y = {
					{ "progress", separator = " ", padding = { left = 1, right = 0 } },
					{ "location", padding = { left = 0, right = 1 } },
				},
				lualine_z = {
					function()
						return icons.system.clock .. os.date("%R")
					end,
				},
			},
			extensions = { "neo-tree", "lazy" },
		}
	end
}
