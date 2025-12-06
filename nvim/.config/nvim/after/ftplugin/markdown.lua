-- Markdown Todo Plugin
-- Toggle todos and auto-complete parents when all children are done
-- Also checks/unchecks all children when parent is toggled

local M = {}

-- Pattern to match a markdown todo: "- [ ]" or "- [x]"
local todo_pattern = "^(%s*)%- %[([%sx])%]"

--- Check if a line is a todo item
---@param line string
---@return boolean is_todo
---@return string|nil indent
---@return string|nil state ("x" or " ")
local function parse_todo(line)
	local indent, state = line:match(todo_pattern)
	if indent then
		return true, indent, state
	end
	return false, nil, nil
end

--- Get the indentation level (number of spaces/tabs)
---@param indent string
---@return number
local function indent_level(indent)
	-- Convert tabs to spaces (assuming 4 spaces per tab)
	local normalized = indent:gsub("\t", "    ")
	return #normalized
end

--- Set todo state on a specific line
---@param lnum number line number (1-indexed)
---@param new_state string "x" or " "
local function set_todo_state(lnum, new_state)
	local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
	local is_todo, _, state = parse_todo(line)

	if not is_todo or state == new_state then
		return
	end

	local new_line = line:gsub("%- %[" .. state .. "%]", "- [" .. new_state .. "]", 1)
	vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { new_line })
end

--- Toggle the todo on the current line
---@param lnum number line number (1-indexed)
---@return boolean changed whether the line was changed
---@return string|nil new_state the new state after toggle
local function toggle_todo(lnum)
	local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
	local is_todo, indent, state = parse_todo(line)

	if not is_todo then
		return false, nil
	end

	local new_state = state == " " and "x" or " "
	local new_line = line:gsub("%- %[" .. state .. "%]", "- [" .. new_state .. "]", 1)
	vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { new_line })

	return true, new_state
end

--- Find all descendants (children, grandchildren, etc.) of a parent
---@param parent_lnum number
---@param parent_indent number
---@return table[] descendants list of {lnum, state, indent}
local function find_all_descendants(parent_lnum, parent_indent)
	local descendants = {}
	local total_lines = vim.api.nvim_buf_line_count(0)

	for lnum = parent_lnum + 1, total_lines do
		local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
		local is_todo, indent, state = parse_todo(line)

		if is_todo then
			local level = indent_level(indent)
			if level > parent_indent then
				table.insert(descendants, { lnum = lnum, state = state, indent = indent })
			else
				break
			end
		elseif line:match("^%s*$") then
			-- Empty line, continue
		else
			local line_indent = indent_level(line:match("^(%s*)") or "")
			if line_indent <= parent_indent then
				break
			end
		end
	end

	return descendants
end

--- Find all direct children todos of a parent at given line
---@param parent_lnum number
---@param parent_indent number
---@return table[] children list of {lnum, state}
local function find_children(parent_lnum, parent_indent)
	local children = {}
	local total_lines = vim.api.nvim_buf_line_count(0)
	local child_indent_level = nil

	for lnum = parent_lnum + 1, total_lines do
		local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
		local is_todo, indent, state = parse_todo(line)

		if is_todo then
			local level = indent_level(indent)
			if level > parent_indent then
				-- First child determines the indent level for direct children
				if child_indent_level == nil then
					child_indent_level = level
				end
				-- Only include direct children (same indent as first child)
				if level == child_indent_level then
					table.insert(children, { lnum = lnum, state = state, indent = indent })
				end
			else
				break
			end
		elseif line:match("^%s*$") then
			-- Empty line, continue
		else
			local line_indent = indent_level(line:match("^(%s*)") or "")
			if line_indent <= parent_indent then
				break
			end
		end
	end

	return children
end

--- Find the parent todo of a given line
---@param child_lnum number
---@param child_indent number
---@return number|nil parent_lnum
local function find_parent(child_lnum, child_indent)
	for lnum = child_lnum - 1, 1, -1 do
		local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
		local is_todo, indent, _ = parse_todo(line)

		if is_todo then
			local level = indent_level(indent)
			if level < child_indent then
				return lnum
			end
		end
	end
	return nil
end

--- Update all children to match parent state
---@param parent_lnum number
---@param new_state string "x" or " "
local function update_children(parent_lnum, new_state)
	local line = vim.api.nvim_buf_get_lines(0, parent_lnum - 1, parent_lnum, false)[1]
	local _, indent, _ = parse_todo(line)
	local parent_indent = indent_level(indent)

	local descendants = find_all_descendants(parent_lnum, parent_indent)

	for _, desc in ipairs(descendants) do
		set_todo_state(desc.lnum, new_state)
	end
end

--- Check if all children are completed and update parent accordingly
---@param lnum number the line that was just toggled
local function update_parent(lnum)
	local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
	local is_todo, indent, _ = parse_todo(line)

	if not is_todo then
		return
	end

	local child_indent = indent_level(indent)
	local parent_lnum = find_parent(lnum, child_indent)

	if not parent_lnum then
		return
	end

	local parent_line = vim.api.nvim_buf_get_lines(0, parent_lnum - 1, parent_lnum, false)[1]
	local _, parent_indent_str, parent_state = parse_todo(parent_line)
	local parent_indent_level = indent_level(parent_indent_str)

	-- Find all siblings (direct children of parent)
	local siblings = find_children(parent_lnum, parent_indent_level)

	-- Re-read sibling states (they may have been updated)
	local all_complete = true
	for _, sibling in ipairs(siblings) do
		local sib_line = vim.api.nvim_buf_get_lines(0, sibling.lnum - 1, sibling.lnum, false)[1]
		local _, _, sib_state = parse_todo(sib_line)
		if sib_state ~= "x" then
			all_complete = false
			break
		end
	end

	-- Update parent if all children are complete and parent isn't already checked
	if all_complete and parent_state == " " then
		local new_parent = parent_line:gsub("%- %[ %]", "- [x]", 1)
		vim.api.nvim_buf_set_lines(0, parent_lnum - 1, parent_lnum, false, { new_parent })
		-- Recursively check grandparent
		update_parent(parent_lnum)
	elseif not all_complete and parent_state == "x" then
		-- Uncheck parent if not all children are complete
		local new_parent = parent_line:gsub("%- %[x%]", "- [ ]", 1)
		vim.api.nvim_buf_set_lines(0, parent_lnum - 1, parent_lnum, false, { new_parent })
		-- Recursively update grandparent
		update_parent(parent_lnum)
	end
end

--- Main function: toggle todo, update children and parents
function M.toggle()
	local lnum = vim.api.nvim_win_get_cursor(0)[1]

	local changed, new_state = toggle_todo(lnum)
	if changed then
		-- Update all children to match new state
		update_children(lnum, new_state)
		-- Update parent based on sibling states
		update_parent(lnum)
	end
end

--- Create a new todo on the next line
---@param nested boolean whether to create a nested (indented) todo
function M.new_todo(nested)
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
	local is_todo, indent, _ = parse_todo(line)

	local new_indent = ""
	if is_todo then
		new_indent = indent
		if nested then
			-- Add one level of indentation (use tab or spaces based on buffer settings)
			local use_tabs = not vim.bo.expandtab
			if use_tabs then
				new_indent = new_indent .. "\t"
			else
				local sw = vim.bo.shiftwidth
				if sw == 0 then sw = vim.bo.tabstop end
				new_indent = new_indent .. string.rep(" ", sw)
			end
		end
	else
		-- Not on a todo, just use current line's indentation
		new_indent = line:match("^(%s*)") or ""
	end

	local new_line = new_indent .. "- [ ] "
	vim.api.nvim_buf_set_lines(0, lnum, lnum, false, { new_line })
	-- Move cursor to end of new line
	vim.api.nvim_win_set_cursor(0, { lnum + 1, #new_line })
	-- Enter insert mode at end of line
	vim.cmd("startinsert!")
end

--- Smart 'o' - if on a todo line, create another todo; otherwise normal 'o'
function M.smart_open_below()
	local lnum = vim.api.nvim_win_get_cursor(0)[1]
	local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
	local is_todo, indent, _ = parse_todo(line)

	if is_todo then
		-- Check if the todo text is empty (just "- [ ] " with nothing after)
		local todo_text = line:match("%- %[.%]%s*(.*)")
		if todo_text == "" then
			-- Empty todo, convert to empty line and do normal 'o'
			vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { "" })
			vim.cmd("normal! o")
		else
			-- Create new todo at same level
			M.new_todo(false)
		end
	else
		-- Not a todo, normal behavior
		vim.cmd("normal! o")
	end
end

-- Set up keymaps for markdown files
vim.keymap.set("n", "<CR>", M.toggle, { buffer = true, desc = "Toggle markdown todo" })
vim.keymap.set("n", "<leader>tt", M.toggle, { buffer = true, desc = "[T]oggle [T]odo" })
vim.keymap.set("n", "<leader>tn", function() M.new_todo(false) end, { buffer = true, desc = "[T]odo [N]ew" })
vim.keymap.set("n", "<leader>tN", function() M.new_todo(true) end, { buffer = true, desc = "[T]odo [N]ested" })
vim.keymap.set("n", "o", M.smart_open_below, { buffer = true, desc = "Smart open below" })

return M
