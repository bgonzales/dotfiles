return {
	{
		-- Better vim.* completion inside lua files
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
		opts = {
			library = {
				-- See the configuration section for more details
				-- Load luvit types when the `vim.uv` word is found
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } }
			}
		}
	},
	{
		'saghen/blink.cmp',
		dependencies = { 'rafamadriz/friendly-snippets' },

		-- use a release tag to download pre-built binaries
		version = '1.*',
		opts = {
			-- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
			-- 'super-tab' for mappings similar to vscode (tab to accept)
			-- 'enter' for enter to accept
			-- 'none' for no mappings
			--
			-- All presets have the following mappings:
			-- C-space: Open menu or open docs if already open
			-- C-n/C-p or Up/Down: Select next/previous item
			-- C-e: Hide menu
			-- C-k: Toggle signature help (if signature.enabled = true)
			--
			-- See :h blink-cmp-config-keymap for defining your own keymap
			keymap = { preset = 'enter' },

			completion = { documentation = { auto_show = true } },

			appearance = {
				-- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
				-- Adjusts spacing to ensure icons are aligned
				nerd_font_variant = 'mono'
			},

			signature = { enabled = true },
		},
	},
	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"neovim/nvim-lspconfig",
		},
		opts = function()
			local capabilities = require('blink.cmp').get_lsp_capabilities()
			return {
				ensure_installed = {
					"lua_ls",
					"clangd",
					"texlab",
					"html",
					"cssls",
					"tailwindcss",
					"ts_ls",
					"eslint",
					"jsonls",
					"docker_compose_language_service",
					"dockerls"
				},
				automatic_installation = true,
				handlers = {
					function(server_name)
						require('lspconfig')[server_name].setup {
							capabilities = capabilities,
						}
					end,
				},
			}
		end
	}
}
