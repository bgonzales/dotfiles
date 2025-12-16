local M = {}

local runner = require("codemate.runner")

-- Icons for different states
local icons = {
  idle = "",
  running = "",
  success = "",
  failed = "",
}

-- Highlight groups
local highlights = {
  idle = "Comment",
  running = "DiagnosticInfo",
  success = "DiagnosticOk",
  failed = "DiagnosticError",
}

-- Get statusline component (plain text)
function M.get()
  local status = runner.get_status()

  if status.status == "idle" then
    return ""
  end

  local icon = icons[status.status] or ""

  if status.is_running then
    return icon .. " Running..."
  elseif status.status == "success" then
    return icon .. " Success"
  elseif status.status == "failed" then
    return icon .. " Failed"
  end

  return ""
end

-- Get statusline component with highlight
function M.get_hl()
  local status = runner.get_status()

  if status.status == "idle" then
    return "", nil
  end

  local icon = icons[status.status] or ""
  local hl = highlights[status.status]

  if status.is_running then
    return icon .. " Running...", hl
  elseif status.status == "success" then
    return icon .. " Success", hl
  elseif status.status == "failed" then
    return icon .. " Failed", hl
  end

  return "", nil
end

-- For lualine integration
function M.lualine()
  return {
    function()
      return M.get()
    end,
    cond = function()
      local status = runner.get_status()
      return status.status ~= "idle"
    end,
    color = function()
      local status = runner.get_status()
      local colors = {
        running = { fg = "#61afef" },
        success = { fg = "#98c379" },
        failed = { fg = "#e06c75" },
      }
      return colors[status.status]
    end,
  }
end

-- For heirline integration
function M.heirline()
  return {
    provider = function()
      return M.get()
    end,
    condition = function()
      local status = runner.get_status()
      return status.status ~= "idle"
    end,
    hl = function()
      local status = runner.get_status()
      return highlights[status.status]
    end,
  }
end

-- Progress bar component
function M.progress_bar(width)
  width = width or 10
  local status = runner.get_status()

  if not status.is_running then
    return ""
  end

  local filled = math.floor(status.progress / 100 * width)
  local empty = width - filled

  return "[" .. string.rep("█", filled) .. string.rep("░", empty) .. "]"
end

-- Combined component with progress
function M.get_with_progress()
  local status = runner.get_status()

  if status.status == "idle" then
    return ""
  end

  local icon = icons[status.status] or ""

  if status.is_running then
    local bar = M.progress_bar(8)
    return icon .. " " .. bar
  elseif status.status == "success" then
    return icon .. " Success"
  elseif status.status == "failed" then
    return icon .. " Failed"
  end

  return ""
end

return M
