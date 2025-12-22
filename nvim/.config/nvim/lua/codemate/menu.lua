local M = {}

local runner = require("codemate.runner")
local history = require("codemate.history")

local ns = vim.api.nvim_create_namespace("codemate_menu")

local actions = {
  { key = "r", icon = "", label = "Run", desc = "Run current project", fn = function() runner.run() end },
  { key = "b", icon = "", label = "Build", desc = "Build current project", fn = function() runner.build() end },
  { key = "t", icon = "", label = "Test", desc = "Run tests", fn = function() runner.test() end },
  { key = "l", icon = "", label = "Re-run", desc = "Re-run last command", fn = function() runner.rerun() end },
  { key = "k", icon = "", label = "Stop", desc = "Stop running process", fn = function() runner.stop() end },
  { key = "o", icon = "", label = "Toggle", desc = "Toggle output window", fn = function() runner.toggle() end },
  { key = "i", icon = "", label = "Info", desc = "Show project info", fn = function() runner.info() end },
  { key = "n", icon = "", label = "New", desc = "Create new project/file", fn = function() require("codemate.picker").pick_template() end },
  { key = "d", icon = "", label = "Dashboard", desc = "Open project dashboard", fn = function() require("codemate.dashboard").open() end },
  { key = "h", icon = "", label = "History", desc = "Show build history", fn = function() history.pick() end },
}

local function render_menu(buf)
  local lines = {}
  local highlights = {}

  table.insert(lines, "")
  table.insert(lines, "  Codemate Actions")
  table.insert(highlights, { #lines - 1, "Title", 2, -1 })
  table.insert(lines, "")

  for _, action in ipairs(actions) do
    local line = string.format("  [%s]  %s  %-10s %s", action.key, action.icon, action.label, action.desc)
    table.insert(lines, line)

    -- Highlight key
    table.insert(highlights, { #lines - 1, "Special", 2, 5 })
    -- Highlight icon
    table.insert(highlights, { #lines - 1, "Function", 7, 10 })
    -- Highlight description
    table.insert(highlights, { #lines - 1, "Comment", 22, -1 })
  end

  table.insert(lines, "")
  table.insert(lines, "  Press key to execute • q/Esc to close")
  table.insert(highlights, { #lines - 1, "Comment", 0, -1 })
  table.insert(lines, "")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Apply highlights
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(buf, ns, hl[2], hl[1], hl[3], hl[4])
  end
end

function M.open()
  local width = 50
  local height = #actions + 6

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "codemate_menu"

  -- Calculate center position
  local ui = vim.api.nvim_list_uis()[1]
  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)

  -- Create window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Quick Actions ",
    title_pos = "center",
  })

  vim.wo[win].cursorline = false
  vim.wo[win].number = false

  -- Render content
  render_menu(buf)

  -- Setup keymaps
  local opts = { buffer = buf, nowait = true, silent = true }

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)

  for _, action in ipairs(actions) do
    vim.keymap.set("n", action.key, function()
      close()
      vim.schedule(action.fn)
    end, opts)
  end
end

return M
