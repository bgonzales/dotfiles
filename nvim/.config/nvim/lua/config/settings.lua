-- [[ Vim Settings ]]

-- Setup leader keys. <LocalLeader> is to be used for mappings which are local to a buffer.
vim.g.mapleader = ','
vim.g.maplocalleader = ','

-- Exclude build directories from LSP file watching
-- Prevents errors with temporary files (e.g., Swift .build/*.pcm.lock)
local watch_type = require("vim._watch").FileChangeType
local original_watch = vim.lsp.util._watchfiles

if original_watch then
	vim.lsp.util._watchfiles = function(path, opts, callback)
		-- Patterns to ignore
		local ignore_patterns = {
			"%.build/",      -- Swift
			"/build/",       -- CMake, Gradle
			"/target/",      -- Rust/Cargo
			"node_modules/", -- Node
			"__pycache__/",  -- Python
			"%.pcm%.lock$",  -- Swift module cache locks
		}

		local wrapped_callback = function(filepath, change_type)
			for _, pattern in ipairs(ignore_patterns) do
				if filepath:match(pattern) then
					return
				end
			end
			callback(filepath, change_type)
		end

		return original_watch(path, opts, wrapped_callback)
	end
end

-- Enable line numbers and relative position
vim.opt.number = true
vim.opt.relativenumber = true

-- Highlight current line
vim.opt.cursorline = true

-- Highlight on search
vim.opt.hlsearch = true

-- Number of spaces that a <Tab> in the file counts for.
vim.opt.tabstop = 4

-- Number of spaces that a <Tab> counts for while performing editing operations, like inserting a <Tab> or using <BS>.
vim.opt.softtabstop = 4

-- Number of spaces to use for each step of (auto)indent.
vim.opt.shiftwidth = 4

vim.opt.clipboard = 'unnamedplus'

-- menu		only shown when there is more than one match
-- menuone	when there is only one match.
-- preview	show extra information about the currently selected completion in the preview window.
vim.opt.completeopt = {'menu', 'menuone', 'preview', 'noselect'}

-- Mouse support for [a]ll Vim modes
vim.opt.mouse = 'a'

-- Save undo history
vim.opt.undofile = true

-- Disable netrw browser
vim.g.loaded_netrw = 0
vim.g.loaded_netrwPlugin = 0

-- Always show sign column
vim.opt.signcolumn = 'yes'

-- Case of normal letters is ignored
vim.opt.ignorecase = true

-- Override the 'ignorecase' option if the search pattern contains upper case characters.
vim.opt.smartcase = true

-- Enables 24-bit RGB colors
vim.opt.termguicolors = true

-- Spell checking, if words are not recognized they are highlighted see `:help spell`
vim.opt.spell = true
vim.opt.spelllang = { 'en_us' }

-- Split orientation
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Save all changes when pressing Ctrl+s (deprecated due to native signature option)
-- vim.keymap.set('i', '<C-s>', '<Esc>:wa<CR>')
-- Mapping save option to unused (probably) keymap, should match ghostty configuration
vim.keymap.set({'n', 'i', 'v', 's'}, '<C-n>', '<CMD>wa<CR><ESC>')

-- Change from insert to normal mode inside terminal buffer
vim.keymap.set('t', '<Esc>', '<C-\\><c-n>')

-- Move current/selected lines
vim.keymap.set("n", "<C-j>", "<CMD>m . +1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "<C-k>", "<CMD>m . -2<CR>==", { desc = "Move line up" })
vim.keymap.set("v", "<C-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<C-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })


-- [[ Vim AutoCMD ]]

-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = '*',
})

-- Resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
	group = vim.api.nvim_create_augroup('ResizeSplits', { clear = true }),
	callback = function()
		vim.cmd("tabdo wincmd =")
	end,
})

-- Open help panel on the right
vim.api.nvim_create_autocmd("BufWinEnter", {
	group = vim.api.nvim_create_augroup("HelpWindowRight", {}),
	pattern = { "*.txt" },
	callback = function()
		if vim.o.filetype == 'help' then vim.cmd.wincmd("L") end
	end
})

-- Disables highlight for group SpellBad. Run :filter Spell highlight
--
-- BufNewFile   When starting to edit a file that doesn't exist.
-- BufReadPost	When starting to edit a new buffer, after reading the file into the buffer.
vim.api.nvim_create_autocmd({"BufNewFile", "BufRead", "TermOpen", "ColorScheme"}, {
	group = vim.api.nvim_create_augroup("NoSpellHighlight", {}),
	callback = function()
		vim.cmd("hi clear SpellBad")
		vim.cmd("hi clear SpellLocal")
	end,
})
