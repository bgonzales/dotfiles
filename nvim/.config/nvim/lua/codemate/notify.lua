local M = {}

local has_notify, notify = pcall(require, "notify")

local icons = {
  run = "",
  build = "",
  test = "",
  success = "",
  failed = "",
  stop = "",
  info = "",
}

-- Configure notify for codemate if available
local function setup_notify()
  if not has_notify then return end

  notify.setup({
    stages = "fade_in_slide_out",
    timeout = 3000,
  })
end

-- Show a notification
function M.info(msg, title)
  title = title or "Codemate"
  if has_notify then
    notify(msg, vim.log.levels.INFO, {
      title = title,
      icon = icons.info,
    })
  else
    vim.notify(msg, vim.log.levels.INFO)
  end
end

-- Show start notification
function M.start(type, project_name)
  local icon = icons[type] or icons.run
  local action = type == "build" and "Building" or (type == "test" and "Testing" or "Running")
  local msg = action .. " " .. project_name .. "..."

  if has_notify then
    return notify(msg, vim.log.levels.INFO, {
      title = "Codemate",
      icon = icon,
      timeout = false, -- Don't auto-dismiss
      hide_from_history = true,
    })
  else
    vim.notify(msg, vim.log.levels.INFO)
    return nil
  end
end

-- Show success notification
function M.success(type, project_name, duration, replace_id)
  local icon = icons.success
  local action = type == "build" and "Built" or (type == "test" and "Tested" or "Ran")
  local duration_str = duration and string.format(" in %.1fs", duration) or ""
  local msg = action .. " " .. project_name .. duration_str

  if has_notify then
    notify(msg, vim.log.levels.INFO, {
      title = "Codemate",
      icon = icon,
      replace = replace_id,
      timeout = 3000,
    })
  else
    vim.notify(icons.success .. " " .. msg, vim.log.levels.INFO)
  end
end

-- Show failure notification
function M.failure(type, project_name, exit_code, error_count, replace_id)
  local icon = icons.failed
  local action = type == "build" and "Build" or (type == "test" and "Test" or "Run")
  local msg = action .. " failed"
  if exit_code then
    msg = msg .. " (exit " .. exit_code .. ")"
  end
  if error_count and error_count > 0 then
    msg = msg .. "\n" .. error_count .. " error(s) found"
  end

  if has_notify then
    notify(msg, vim.log.levels.ERROR, {
      title = "Codemate • " .. project_name,
      icon = icon,
      replace = replace_id,
      timeout = 5000,
    })
  else
    vim.notify(icons.failed .. " " .. msg, vim.log.levels.ERROR)
  end
end

-- Show stop notification
function M.stopped()
  if has_notify then
    notify("Process stopped", vim.log.levels.WARN, {
      title = "Codemate",
      icon = icons.stop,
      timeout = 2000,
    })
  else
    vim.notify(icons.stop .. " Process stopped", vim.log.levels.WARN)
  end
end

-- Show progress notification (updates existing)
function M.progress(msg, progress_pct, replace_id)
  if not has_notify then return nil end

  local bar_width = 20
  local filled = math.floor(progress_pct / 100 * bar_width)
  local bar = string.rep("█", filled) .. string.rep("░", bar_width - filled)

  return notify(msg .. "\n" .. bar .. " " .. progress_pct .. "%", vim.log.levels.INFO, {
    title = "Codemate",
    icon = icons.build,
    replace = replace_id,
    timeout = false,
    hide_from_history = true,
  })
end

-- Render timeline notification
function M.timeline(phases)
  if not has_notify then return end

  local lines = {}
  local total = 0

  for _, phase in ipairs(phases) do
    total = total + phase.duration
  end

  for _, phase in ipairs(phases) do
    local pct = math.floor(phase.duration / total * 100)
    local bar_width = math.floor(pct / 5)
    local bar = string.rep("▓", bar_width)
    local status = phase.success and "" or ""
    table.insert(lines, string.format("%s %-12s %s %.1fs", status, phase.name, bar, phase.duration))
  end

  table.insert(lines, string.rep("─", 30))
  table.insert(lines, string.format("Total: %.1fs", total))

  notify(table.concat(lines, "\n"), vim.log.levels.INFO, {
    title = "Build Timeline",
    icon = icons.build,
    timeout = 8000,
  })
end

setup_notify()

return M
