local M = {}

local history = require("codemate.history")
local runner = require("codemate.runner")

local ns = vim.api.nvim_create_namespace("codemate_dashboard")

local config = {
  width = 60,
  height = 20,
}

local icons = {
  run = "",
  build = "",
  test = "",
  success = "",
  failed = "",
  clock = "",
  folder = "",
  file = "",
  arrow = "",
}

local function center_text(text, width)
  local padding = math.floor((width - vim.fn.strdisplaywidth(text)) / 2)
  return string.rep(" ", padding) .. text
end

local function get_project_info()
  local cwd = vim.fn.getcwd()
  local name = vim.fn.fnamemodify(cwd, ":t")

  -- Detect project type
  local project_type = "Unknown"
  local project_icon = icons.folder

  if vim.fn.filereadable(cwd .. "/Package.swift") == 1 then
    project_type = "Swift Package"
    project_icon = ""
  elseif vim.fn.filereadable(cwd .. "/Cargo.toml") == 1 then
    project_type = "Rust/Cargo"
    project_icon = ""
  elseif vim.fn.filereadable(cwd .. "/go.mod") == 1 then
    project_type = "Go Module"
    project_icon = ""
  elseif vim.fn.filereadable(cwd .. "/CMakeLists.txt") == 1 then
    project_type = "CMake"
    project_icon = ""
  elseif vim.fn.filereadable(cwd .. "/Makefile") == 1 then
    project_type = "Makefile"
    project_icon = ""
  elseif vim.fn.filereadable(cwd .. "/build.gradle.kts") == 1 or vim.fn.filereadable(cwd .. "/build.gradle") == 1 then
    project_type = "Kotlin/Gradle"
    project_icon = ""
  elseif vim.fn.filereadable(cwd .. "/pyproject.toml") == 1 or vim.fn.filereadable(cwd .. "/requirements.txt") == 1 then
    project_type = "Python"
    project_icon = ""
  end

  return {
    name = name,
    path = cwd,
    type = project_type,
    icon = project_icon,
  }
end

local function format_duration(seconds)
  if seconds < 60 then
    return string.format("%.1fs", seconds)
  else
    local mins = math.floor(seconds / 60)
    local secs = seconds % 60
    return string.format("%dm %.1fs", mins, secs)
  end
end

local function format_time_ago(timestamp)
  local now = os.time()
  local diff = now - timestamp

  if diff < 60 then
    return "just now"
  elseif diff < 3600 then
    return math.floor(diff / 60) .. "m ago"
  elseif diff < 86400 then
    return math.floor(diff / 3600) .. "h ago"
  else
    return math.floor(diff / 86400) .. "d ago"
  end
end

local function render_dashboard(buf, win)
  local width = config.width
  local lines = {}
  local highlights = {}

  local project = get_project_info()
  local recent = history.get_all()

  -- Filter to current project
  local project_history = {}
  for _, entry in ipairs(recent) do
    if entry.project_path == project.path then
      table.insert(project_history, entry)
      if #project_history >= 5 then break end
    end
  end

  -- Header
  table.insert(lines, "")
  table.insert(lines, center_text("╭─────────────────────────────────╮", width))
  table.insert(lines, center_text("│       CODEMATE DASHBOARD        │", width))
  table.insert(lines, center_text("╰─────────────────────────────────╯", width))
  table.insert(lines, "")

  -- Project Info
  local project_line = project.icon .. "  " .. project.name
  table.insert(lines, center_text(project_line, width))
  table.insert(highlights, { #lines - 1, "Title" })

  table.insert(lines, center_text(project.type .. " • " .. project.path, width))
  table.insert(highlights, { #lines - 1, "Comment" })
  table.insert(lines, "")

  -- Quick Actions
  table.insert(lines, "  Quick Actions")
  table.insert(highlights, { #lines - 1, "Special" })
  table.insert(lines, "")
  table.insert(lines, "    [r] " .. icons.run .. "  Run        [b] " .. icons.build .. "  Build      [t] " .. icons.test .. "  Test")
  table.insert(lines, "    [l] " .. icons.arrow .. "  Re-run     [k]   Stop       [o]   Toggle")
  table.insert(lines, "")

  -- Recent Activity
  table.insert(lines, "  Recent Activity")
  table.insert(highlights, { #lines - 1, "Special" })
  table.insert(lines, "")

  if #project_history == 0 then
    table.insert(lines, "    No recent builds or runs")
    table.insert(highlights, { #lines - 1, "Comment" })
  else
    for i, entry in ipairs(project_history) do
      local status_icon = entry.exit_code == 0 and icons.success or icons.failed
      local status_hl = entry.exit_code == 0 and "DiagnosticOk" or "DiagnosticError"
      local type_icon = entry.type == "build" and icons.build or (entry.type == "test" and icons.test or icons.run)

      local duration_str = entry.duration and format_duration(entry.duration) or "—"
      local time_str = entry.timestamp and format_time_ago(entry.timestamp) or ""

      local line = string.format("    %s %s %-8s  %s  %s",
        status_icon, type_icon, entry.type or "run", duration_str, time_str)
      table.insert(lines, line)
      table.insert(highlights, { #lines - 1, status_hl, 4, 6 })
    end
  end

  table.insert(lines, "")

  -- Status
  local status = runner.get_status()
  if status.is_running then
    table.insert(lines, "   Running...")
    table.insert(highlights, { #lines - 1, "DiagnosticInfo" })
  end

  -- Footer
  table.insert(lines, "")
  table.insert(lines, center_text("Press key to execute • q/Esc to close", width))
  table.insert(highlights, { #lines - 1, "Comment" })

  -- Set lines
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Apply highlights
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, hl in ipairs(highlights) do
    local line_idx = hl[1]
    local hl_group = hl[2]
    local col_start = hl[3] or 0
    local col_end = hl[4] or -1
    vim.api.nvim_buf_add_highlight(buf, ns, hl_group, line_idx, col_start, col_end)
  end
end

function M.open()
  local width = config.width
  local height = config.height

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "codemate_dashboard"

  -- Calculate position
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
    title = " Codemate ",
    title_pos = "center",
  })

  vim.wo[win].winblend = 0
  vim.wo[win].cursorline = false

  -- Render content
  render_dashboard(buf, win)

  -- Keymaps
  local opts = { buffer = buf, nowait = true, silent = true }

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local function action(fn)
    return function()
      close()
      vim.schedule(fn)
    end
  end

  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)
  vim.keymap.set("n", "r", action(runner.run), opts)
  vim.keymap.set("n", "b", action(runner.build), opts)
  vim.keymap.set("n", "t", action(runner.test), opts)
  vim.keymap.set("n", "l", action(runner.rerun), opts)
  vim.keymap.set("n", "k", action(runner.stop), opts)
  vim.keymap.set("n", "o", action(runner.toggle), opts)
  vim.keymap.set("n", "p", action(function()
    require("codemate.picker").pick_template()
  end), opts)
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
end

return M
