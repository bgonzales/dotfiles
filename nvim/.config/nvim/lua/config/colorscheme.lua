local themes = {
	dark = "tokyonight",
	light = "xcode",
	-- light = "catppuccin",
	-- light = "noctis_hibernus",
	-- light = "tokyonight-day"
}

local function apply_colorscheme()
	local bg = vim.o.background
	local theme = themes[bg] or "xcode"
	vim.cmd("colorscheme " .. theme)
end

apply_colorscheme()

-- Auto-reload theme when background changes
vim.api.nvim_create_autocmd("OptionSet", {
	pattern = "background",
	callback = apply_colorscheme,
})

