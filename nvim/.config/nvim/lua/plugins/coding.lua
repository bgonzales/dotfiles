return {
	{
		-- Better vim.* completion inside lua files
		"folke/lazydev.nvim",
		ft = "lua", -- only load on lua files
		opts = {
			library = {
				-- See the configuration section for more details
				-- Load luvit types when the `vim.uv` word is found
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},
	{
		"saghen/blink.cmp",
		dependencies = { "rafamadriz/friendly-snippets" },

		-- use a release tag to download pre-built binaries
		version = "1.*",
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
			keymap = { preset = "enter" },

			-- Completion menu appearance (optimized for speed)
			completion = {
				menu = {
					border = "rounded",
					scrollbar = true,
					auto_show = true, -- Show completion menu automatically
					-- Using default draw for maximum performance
				},
				documentation = {
					auto_show = false, -- Manual show for best performance (use C-space when needed)
					window = {
						border = "rounded",
					},
				},
			},


			-- Appearance configuration (using defaults for speed)
			appearance = {
				nerd_font_variant = "mono",
				use_nvim_cmp_as_default = true,
				-- Using default kind_icons for better performance
			},

			-- Signature help
			signature = {
				enabled = true,
				window = { border = "rounded" },
			},
		},
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
		},
		opts = {
			ensure_installed = {
				-- Formatters
				"prettier", -- JS/TS/HTML/CSS/JSON/Markdown
				"stylua", -- Lua
				-- swiftformat NOT in Mason - install via: brew install swiftformat
				"ruff", -- Python (formatter + linter)
				-- goimports NOT in Mason - requires Go installation
				"clang-format", -- C/C++
				"latexindent", -- LaTeX
				-- Linters
				-- swiftlint NOT in Mason - install via: brew install swiftlint
				-- eslint_d: Not needed, eslint LSP provides diagnostics for JS/TS (matches LazyVim)
				-- selene: Not needed, lua_ls provides diagnostics for Lua
				"markdownlint", -- Markdown
				"shellcheck", -- Shell scripts
				"hadolint", -- Dockerfile
				-- golangci-lint NOT in Mason - requires Go installation
				"stylelint", -- CSS/SCSS
				"yamllint", -- YAML
				-- clang-tidy NOT in Mason - integrated into clangd LSP
				-- cppcheck NOT in Mason - install via: brew install cppcheck
				-- chktex NOT in Mason - install via: brew install chktex (or use texlab LSP)
			},
			auto_update = false,
			run_on_start = true,
		},
	},
	{
		"mason-org/mason-lspconfig.nvim",
		dependencies = {
			"mason-org/mason.nvim",
			"neovim/nvim-lspconfig",
		},
		opts = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()
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
					"pyright",
					"ruff",
					-- gopls requires Go installation
					"rust_analyzer",
					"marksman",
					"svelte",
					"docker_compose_language_service",
					"dockerls",
				},
				automatic_installation = true,
				handlers = {
					function(server_name)
						require("lspconfig")[server_name].setup({
							capabilities = capabilities,
						})
					end,
				},
			}
		end,
	},
}
