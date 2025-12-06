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
		vim.keymap.set('n', '<leader>ff', vim.lsp.buf.format, { buffer = ev.buf, desc = '[F]ormat [F]ile' })
	end
})

if vim.uv.os_uname().sysname == "Darwin" then
	vim.lsp.enable('sourcekit')
end
