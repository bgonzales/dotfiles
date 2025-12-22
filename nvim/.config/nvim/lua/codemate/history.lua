local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

-- Storage location: ~/.local/share/nvim/codemate/
local data_dir = vim.fn.stdpath("data") .. "/codemate"
local history_file = data_dir .. "/history.json"
local logs_dir = data_dir .. "/logs"

local MAX_ENTRIES = 50

local function ensure_dirs()
  vim.fn.mkdir(data_dir, "p")
  vim.fn.mkdir(logs_dir, "p")
end

local function read_history()
  if vim.fn.filereadable(history_file) == 0 then
    return {}
  end

  local content = vim.fn.readfile(history_file)
  if #content == 0 then
    return {}
  end

  local ok, data = pcall(vim.json.decode, table.concat(content, "\n"))
  if ok then
    return data
  end
  return {}
end

local function write_history(entries)
  ensure_dirs()
  local json = vim.json.encode(entries)
  vim.fn.writefile({ json }, history_file)
end

function M.add(entry)
  ensure_dirs()

  local history = read_history()

  -- Generate unique ID for log file
  local id = os.time() .. "_" .. math.random(1000, 9999)

  local record = {
    id = id,
    timestamp = os.time(),
    date = os.date("%Y-%m-%d %H:%M:%S"),
    type = entry.type,           -- "run" or "build"
    project_type = entry.project_type,
    project_name = entry.project_name,
    project_path = entry.project_path,
    cmd = entry.cmd,
    icon = entry.icon or "",
    exit_code = nil,             -- Set on completion
    duration = nil,              -- Set on completion
    log_file = logs_dir .. "/" .. id .. ".log",
  }

  -- Insert at beginning
  table.insert(history, 1, record)

  -- Trim to max entries and clean up old log files
  while #history > MAX_ENTRIES do
    local old = table.remove(history)
    if old.log_file and vim.fn.filereadable(old.log_file) == 1 then
      vim.fn.delete(old.log_file)
    end
  end

  write_history(history)

  return record
end

function M.update(id, updates)
  local history = read_history()

  for i, entry in ipairs(history) do
    if entry.id == id then
      for k, v in pairs(updates) do
        history[i][k] = v
      end
      break
    end
  end

  write_history(history)
end

function M.append_log(record, text)
  if not record or not record.log_file then return end
  ensure_dirs()

  local file = io.open(record.log_file, "a")
  if file then
    file:write(text)
    file:close()
  end
end

function M.get_all()
  return read_history()
end

function M.get_log(record)
  if not record or not record.log_file then
    return nil
  end

  if vim.fn.filereadable(record.log_file) == 1 then
    return vim.fn.readfile(record.log_file)
  end

  return nil
end

function M.clear()
  -- Delete all log files
  local logs = vim.fn.glob(logs_dir .. "/*.log", false, true)
  for _, log in ipairs(logs) do
    vim.fn.delete(log)
  end

  -- Clear history file
  write_history({})

  vim.notify("Codemate history cleared", vim.log.levels.INFO)
end

function M.clear_old(days)
  days = days or 7
  local cutoff = os.time() - (days * 24 * 60 * 60)
  local history = read_history()
  local new_history = {}

  for _, entry in ipairs(history) do
    if entry.timestamp >= cutoff then
      table.insert(new_history, entry)
    else
      -- Delete old log file
      if entry.log_file and vim.fn.filereadable(entry.log_file) == 1 then
        vim.fn.delete(entry.log_file)
      end
    end
  end

  write_history(new_history)
  vim.notify(string.format("Cleared %d old entries", #history - #new_history), vim.log.levels.INFO)
end

local function create_entry_maker()
  return function(entry)
    local icon = entry.icon or ""
    local status_icon = ""
    if entry.exit_code == nil then
      status_icon = "○"  -- Running or unknown
    elseif entry.exit_code == 0 then
      status_icon = "✓"
    else
      status_icon = "✗"
    end

    local duration_str = ""
    if entry.duration then
      if entry.duration < 1 then
        duration_str = string.format("%.0fms", entry.duration * 1000)
      else
        duration_str = string.format("%.1fs", entry.duration)
      end
    end

    local display = string.format(
      "%s %s  %s  %s  %s  %s",
      status_icon,
      icon,
      entry.project_name or "Unknown",
      entry.type or "",
      duration_str,
      entry.date or ""
    )

    return {
      value = entry,
      display = display,
      ordinal = (entry.project_name or "") .. " " .. (entry.date or ""),
    }
  end
end

local function create_previewer()
  return previewers.new_buffer_previewer({
    title = "Output Log",
    define_preview = function(self, entry)
      local record = entry.value
      local lines = {}

      -- Header info
      table.insert(lines, "Project: " .. (record.project_name or "Unknown"))
      table.insert(lines, "Type: " .. (record.type or "Unknown") .. " (" .. (record.project_type or "") .. ")")
      table.insert(lines, "Path: " .. (record.project_path or ""))
      table.insert(lines, "Command: " .. (record.cmd or ""))
      table.insert(lines, "Date: " .. (record.date or ""))

      if record.exit_code ~= nil then
        table.insert(lines, "Exit Code: " .. record.exit_code)
      end
      if record.duration then
        table.insert(lines, string.format("Duration: %.2fs", record.duration))
      end

      table.insert(lines, "")
      table.insert(lines, "─── Output ───")
      table.insert(lines, "")

      -- Log content
      local log_lines = M.get_log(record)
      if log_lines then
        vim.list_extend(lines, log_lines)
      else
        table.insert(lines, "(no output captured)")
      end

      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
    end,
  })
end

local function create_mappings(prompt_bufnr, map)
  -- Re-run on enter
  actions.select_default:replace(function()
    local selection = action_state.get_selected_entry()
    actions.close(prompt_bufnr)
    if selection and selection.value.cmd then
      local record = selection.value
      vim.schedule(function()
        -- Re-run the same command
        require("codemate.runner").run_cmd(
          record.cmd,
          record.project_path,
          record.icon .. "  " .. record.project_name,
          {
            type = record.type,
            project_type = record.project_type,
            project_name = record.project_name,
          }
        )
      end)
    end
  end)

  -- Delete entry with <C-d>
  map("i", "<C-d>", function()
    local selection = action_state.get_selected_entry()
    if selection then
      local record = selection.value
      -- Delete log file
      if record.log_file and vim.fn.filereadable(record.log_file) == 1 then
        vim.fn.delete(record.log_file)
      end
      -- Remove from history
      local hist = read_history()
      for i, e in ipairs(hist) do
        if e.id == record.id then
          table.remove(hist, i)
          break
        end
      end
      write_history(hist)

      -- Refresh picker
      local current_picker = action_state.get_current_picker(prompt_bufnr)
      current_picker:refresh(finders.new_table({
        results = read_history(),
        entry_maker = create_entry_maker(),
      }), { reset_prompt = false })
    end
  end)

  return true
end

-- Telescope picker for history (all projects)
function M.pick()
  local all_history = read_history()

  if #all_history == 0 then
    vim.notify("No history yet", vim.log.levels.INFO)
    return
  end

  pickers.new({}, {
    prompt_title = "  Build/Run History (All)",
    finder = finders.new_table({
      results = all_history,
      entry_maker = create_entry_maker(),
    }),
    sorter = conf.generic_sorter({}),
    previewer = create_previewer(),
    attach_mappings = create_mappings,
  }):find()
end

-- Telescope picker for current project history only
function M.pick_current()
  local cwd = vim.fn.getcwd()
  local all_history = read_history()

  -- Filter to current project path
  local project_history = vim.tbl_filter(function(entry)
    return entry.project_path and entry.project_path:find(cwd, 1, true) == 1
  end, all_history)

  if #project_history == 0 then
    vim.notify("No history for current project", vim.log.levels.INFO)
    return
  end

  local project_name = vim.fn.fnamemodify(cwd, ":t")

  pickers.new({}, {
    prompt_title = "  History: " .. project_name,
    finder = finders.new_table({
      results = project_history,
      entry_maker = create_entry_maker(),
    }),
    sorter = conf.generic_sorter({}),
    previewer = create_previewer(),
    attach_mappings = create_mappings,
  }):find()
end

return M
