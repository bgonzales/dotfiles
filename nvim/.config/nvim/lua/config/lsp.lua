-- Configure rounded borders for LSP floating windows
-- Note: 'rounded' is a built-in style in Neovim that creates nice curved corners
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
	opts = opts or {}
	opts.border = opts.border or 'rounded'
	opts.max_width = opts.max_width or 80
	opts.max_height = opts.max_height or 30
	return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

-- Configure diagnostics
vim.diagnostic.config({
	underline = true,
	update_in_insert = true,
	virtual_text = {
		spacing = 4,
		source = "if_many",
		prefix = "●",
	},
	severity_sort = true,
	float = {
		border = "rounded",
		source = "always",
		header = "",
		prefix = "",
	},
})

vim.api.nvim_create_autocmd('LspAttach', {
	group = vim.api.nvim_create_augroup('UserLspConfig', {}),
	callback = function(ev)
		-- Use conform.nvim for formatting (consistent with ,xcf keybinding)
		vim.keymap.set('n', '<leader>ff', function()
			require('conform').format({ async = true, lsp_format = "fallback" })
		end, { buffer = ev.buf, desc = '[F]ormat [F]ile' })
	end
})

-- Enable SourceKit-LSP for Swift (macOS only)
-- Configuration is defined in lsp/sourcekit.lua (modern neovim 0.10+ pattern)
if vim.uv.os_uname().sysname == "Darwin" then
	vim.lsp.enable('sourcekit')
end
