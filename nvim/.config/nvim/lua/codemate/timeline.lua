local M = {}

local history = require("codemate.history")

local ns = vim.api.nvim_create_namespace("codemate_timeline")

-- Store timeline data
M.data = {
  phases = {},
  total_duration = 0,
}

local icons = {
  success = "",
  failed = "",
  running = "",
  compile = "",
  link = "",
  test = "",
  run = "",
  build = "",
  clock = "",
}

function M.clear()
  M.data = {
    phases = {},
    total_duration = 0,
  }
end

function M.add_phase(name, duration, success, icon)
  table.insert(M.data.phases, {
    name = name,
    duration = duration,
    success = success,
    icon = icon or icons.compile,
    timestamp = os.time(),
  })
  M.data.total_duration = M.data.total_duration + duration
end

function M.start_phase(name, icon)
  return {
    name = name,
    icon = icon or icons.compile,
    start_time = vim.loop.hrtime(),
  }
end

function M.end_phase(phase_handle, success)
  if not phase_handle then return end

  local duration = (vim.loop.hrtime() - phase_handle.start_time) / 1e9
  M.add_phase(phase_handle.name, duration, success, phase_handle.icon)
  return duration
end

local function format_duration(seconds)
  if seconds < 1 then
    return string.format("%dms", math.floor(seconds * 1000))
  elseif seconds < 60 then
    return string.format("%.1fs", seconds)
  else
    return string.format("%dm%.1fs", math.floor(seconds / 60), seconds % 60)
  end
end

local function format_time_ago(timestamp)
  if not timestamp then return "" end

  local now = os.time()
  local diff = now - timestamp

  if diff < 60 then
    return "just now"
  elseif diff < 3600 then
    local mins = math.floor(diff / 60)
    return mins .. " min ago"
  elseif diff < 86400 then
    local hours = math.floor(diff / 3600)
    return hours .. " hour" .. (hours > 1 and "s" or "") .. " ago"
  elseif diff < 604800 then
    local days = math.floor(diff / 86400)
    return days .. " day" .. (days > 1 and "s" or "") .. " ago"
  else
    return os.date("%b %d", timestamp)
  end
end

local function render_bar(duration, total, max_width)
  if total == 0 then return "" end
  local pct = duration / total
  local bar_width = math.max(1, math.floor(pct * max_width))
  return string.rep("█", bar_width)
end

function M.show()
  local cwd = vim.fn.getcwd()
  local all_history = history.get_all()

  -- Filter to current project
  local project_history = {}
  for _, entry in ipairs(all_history) do
    if entry.project_path and entry.project_path:find(cwd, 1, true) == 1 and entry.duration then
      table.insert(project_history, entry)
      if #project_history >= 15 then break end
    end
  end

  if #project_history == 0 then
    vim.notify("No build/run history for this project", vim.log.levels.INFO)
    return
  end

  -- Find max duration for scaling bars
  local max_duration = 0
  for _, entry in ipairs(project_history) do
    if entry.duration and entry.duration > max_duration then
      max_duration = entry.duration
    end
  end

  local width = 70
  local height = #project_history + 10
  local max_bar_width = 20

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "codemate_timeline"

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
    title = " Build & Run Timeline ",
    title_pos = "center",
  })

  -- Render content
  local lines = {}
  local highlights = {}

  local project_name = vim.fn.fnamemodify(cwd, ":t")
  table.insert(lines, "")
  table.insert(lines, "  " .. icons.clock .. "  " .. project_name)
  table.insert(highlights, { #lines - 1, "Title", 0, -1 })
  table.insert(lines, "")
  table.insert(lines, "  Type      Duration   When              Timeline")
  table.insert(highlights, { #lines - 1, "Comment", 0, -1 })
  table.insert(lines, "  " .. string.rep("─", width - 4))
  table.insert(highlights, { #lines - 1, "Comment", 0, -1 })

  -- Calculate stats
  local total_builds = 0
  local total_runs = 0
  local total_tests = 0
  local avg_build_time = 0
  local avg_run_time = 0

  for _, entry in ipairs(project_history) do
    local status_icon = entry.exit_code == 0 and icons.success or icons.failed
    local status_hl = entry.exit_code == 0 and "DiagnosticOk" or "DiagnosticError"

    local type_icon
    if entry.type == "build" then
      type_icon = icons.build
      total_builds = total_builds + 1
      avg_build_time = avg_build_time + (entry.duration or 0)
    elseif entry.type == "test" then
      type_icon = icons.test
      total_tests = total_tests + 1
    else
      type_icon = icons.run
      total_runs = total_runs + 1
      avg_run_time = avg_run_time + (entry.duration or 0)
    end

    local bar = render_bar(entry.duration or 0, max_duration, max_bar_width)
    local duration_str = format_duration(entry.duration or 0)

    -- Format relative time
    local time_ago = format_time_ago(entry.timestamp)

    local line = string.format("  %s %s %-5s  %8s   %-16s  %s",
      status_icon,
      type_icon,
      entry.type or "run",
      duration_str,
      time_ago,
      bar
    )
    table.insert(lines, line)

    -- Highlight status icon
    table.insert(highlights, { #lines - 1, status_hl, 2, 5 })
    -- Highlight bar
    local bar_start = #line - #bar
    table.insert(highlights, { #lines - 1, "DiagnosticInfo", bar_start, -1 })
  end

  table.insert(lines, "  " .. string.rep("─", width - 4))
  table.insert(highlights, { #lines - 1, "Comment", 0, -1 })

  -- Stats summary
  table.insert(lines, "")
  local stats = "  "
  if total_builds > 0 then
    stats = stats .. string.format("%s %d builds (avg %.1fs)  ", icons.build, total_builds, avg_build_time / total_builds)
  end
  if total_runs > 0 then
    stats = stats .. string.format("%s %d runs  ", icons.run, total_runs)
  end
  if total_tests > 0 then
    stats = stats .. string.format("%s %d tests", icons.test, total_tests)
  end
  table.insert(lines, stats)
  table.insert(highlights, { #lines - 1, "Special", 0, -1 })

  table.insert(lines, "")
  table.insert(lines, "  Press q or <Esc> to close")
  table.insert(highlights, { #lines - 1, "Comment", 0, -1 })

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Apply highlights
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(buf, ns, hl[2], hl[1], hl[3], hl[4])
  end

  -- Keymaps
  local opts = { buffer = buf, nowait = true, silent = true }

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)
end

-- Auto-detect phases from build output
function M.parse_output(output, project_type)
  M.clear()

  local patterns = {
    swift = {
      { pattern = "Compiling", name = "Compile", icon = icons.compile },
      { pattern = "Linking", name = "Link", icon = icons.link },
      { pattern = "Build complete", name = "Complete", icon = icons.success },
    },
    cargo = {
      { pattern = "Compiling", name = "Compile", icon = icons.compile },
      { pattern = "Linking", name = "Link", icon = icons.link },
      { pattern = "Finished", name = "Complete", icon = icons.success },
    },
    cmake = {
      { pattern = "Scanning dependencies", name = "Scan", icon = icons.compile },
      { pattern = "Building CXX", name = "Compile", icon = icons.compile },
      { pattern = "Linking CXX", name = "Link", icon = icons.link },
    },
    go = {
      { pattern = "go build", name = "Build", icon = icons.compile },
    },
  }

  -- Simple heuristic: divide total time by detected phases
  -- In real usage, you'd parse timestamps from output
end

-- Show timeline in notification (uses nvim-notify if available)
function M.show_notification()
  local notify_mod = require("codemate.notify")

  if #M.data.phases == 0 then
    return
  end

  notify_mod.timeline(M.data.phases)
end

return M
