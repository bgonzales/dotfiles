---@brief
---
--- https://github.com/swiftlang/sourcekit-lsp
---
--- Language server for Swift and C/C++/Objective-C.

local util = require 'lspconfig.util'

return {
	cmd = { 'sourcekit-lsp' },
	filetypes = { 'swift', 'objc', 'objcpp', 'c', 'cpp' },
	root_dir = function(bufnr, on_dir)
		local filename = vim.api.nvim_buf_get_name(bufnr)
		on_dir(
			util.root_pattern 'buildServer.json' (filename)
			or util.root_pattern('*.xcodeproj', '*.xcworkspace')(filename)
			-- better to keep it at the end, because some modularized apps contain multiple Package.swift files
			or util.root_pattern('compile_commands.json', 'Package.swift')(filename)
			or vim.fs.dirname(vim.fs.find('.git', { path = filename, upward = true })[1])
		)
	end,
	get_language_id = function(_, ftype)
		local t = { objc = 'objective-c', objcpp = 'objective-cpp' }
		return t[ftype] or ftype
	end,
	capabilities = function()
		-- Get capabilities from blink.cmp if available, otherwise use defaults
		local ok, blink = pcall(require, 'blink.cmp')
		local capabilities = ok and blink.get_lsp_capabilities() or vim.lsp.protocol.make_client_capabilities()

		-- Merge with sourcekit-specific capabilities
		capabilities.workspace = vim.tbl_deep_extend('force', capabilities.workspace or {}, {
			didChangeWatchedFiles = {
				dynamicRegistration = true,
			},
		})
		capabilities.textDocument = vim.tbl_deep_extend('force', capabilities.textDocument or {}, {
			diagnostic = {
				dynamicRegistration = true,
				relatedDocumentSupport = true,
			},
		})

		return capabilities
	end,
}
