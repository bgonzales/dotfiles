vim.diagnostic.config({
	underline = true,
	update_in_insert = true,
	virtual_text = {
		spacing = 4,
		source = "if_many",
		prefix = "●",
	},
	severity_sort = true,
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
