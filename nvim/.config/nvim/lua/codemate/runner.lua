local M = {}

local ui = require("codemate.ui")
local history = require("codemate.history")
local notify = require("codemate.notify")
local timeline = require("codemate.timeline")
local testpanel = require("codemate.testpanel")

-- State management
M.state = {
  job_id = nil,
  buf = nil,
  win = nil,
  last_cmd = nil,
  last_cwd = nil,
  last_title = nil,
  last_meta = nil,
  status = "idle", -- idle, running, success, failed
  progress = 0,
  start_time = nil,
}

-- Search upward from a directory to find a file
local function find_root(start_dir, filename)
  local dir = start_dir
  while dir ~= "/" do
    local check = dir .. "/" .. filename
    if vim.fn.filereadable(check) == 1 then
      return dir
    end
    -- Check for glob patterns (like *.xcodeproj)
    if filename:match("%*") then
      local matches = vim.fn.glob(dir .. "/" .. filename)
      if matches ~= "" then
        return dir
      end
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return nil
end

-- Detect project type based on files, searching upward from current file
local function detect_project()
  local file = vim.fn.expand("%:p")
  local filetype = vim.bo.filetype
  local file_dir = vim.fn.expand("%:p:h")

  -- Swift detection
  if filetype == "swift" then
    local spm_root = find_root(file_dir, "Package.swift")
    if spm_root then
      return {
        type = "spm",
        name = "Swift Package",
        path = spm_root,
        build_cmd = "swift build",
        run_cmd = "swift run",
        test_cmd = "swift test",
        icon = "",
        error_pattern = "(%S+):(%d+):(%d+): (%w+): (.+)",
      }
    end

    local xcode_root = find_root(file_dir, "*.xcodeproj")
    if xcode_root then
      return {
        type = "xcode",
        name = "Xcode Project",
        path = xcode_root,
        build_cmd = "xcodebuild -project *.xcodeproj -scheme '*' build",
        run_cmd = "xcodebuild -project *.xcodeproj -scheme '*' build && open build/Debug/*.app 2>/dev/null || swift " .. file,
        icon = "",
      }
    end

    return {
      type = "swift_file",
      name = "Swift File",
      path = file_dir,
      run_cmd = "swift " .. vim.fn.shellescape(file),
      icon = "",
    }
  end

  -- Rust detection
  if filetype == "rust" then
    local cargo_root = find_root(file_dir, "Cargo.toml")
    if cargo_root then
      return {
        type = "cargo",
        name = "Cargo Project",
        path = cargo_root,
        build_cmd = "cargo build",
        run_cmd = "cargo run",
        test_cmd = "cargo test",
        icon = "",
        error_pattern = "error%[E%d+%]: (.+)\n%s+%-%-> ([^:]+):(%d+):(%d+)",
      }
    end

    local out = "/tmp/codemate_" .. vim.fn.fnamemodify(file, ":t:r")
    return {
      type = "rust_file",
      name = "Rust File",
      path = file_dir,
      run_cmd = "rustc " .. vim.fn.shellescape(file) .. " -o " .. out .. " && " .. out,
      icon = "",
    }
  end

  -- Go detection
  if filetype == "go" then
    local go_root = find_root(file_dir, "go.mod")
    if go_root then
      return {
        type = "go_mod",
        name = "Go Module",
        path = go_root,
        build_cmd = "go build",
        run_cmd = "go run .",
        test_cmd = "go test ./...",
        icon = "",
        error_pattern = "([^:]+):(%d+):(%d+): (.+)",
      }
    end

    return {
      type = "go_file",
      name = "Go File",
      path = file_dir,
      run_cmd = "go run " .. vim.fn.shellescape(file),
      icon = "",
    }
  end

  -- Python detection
  if filetype == "python" then
    local venv_root = find_root(file_dir, "pyproject.toml")
      or find_root(file_dir, "setup.py")
      or find_root(file_dir, "requirements.txt")

    if venv_root then
      -- Check for virtual environment
      local python = "python3"
      if vim.fn.isdirectory(venv_root .. "/venv") == 1 then
        python = venv_root .. "/venv/bin/python"
      elseif vim.fn.isdirectory(venv_root .. "/.venv") == 1 then
        python = venv_root .. "/.venv/bin/python"
      end

      return {
        type = "python_project",
        name = "Python Project",
        path = venv_root,
        run_cmd = python .. " " .. vim.fn.shellescape(file),
        test_cmd = python .. " -m pytest",
        icon = "",
        error_pattern = 'File "([^"]+)", line (%d+)',
      }
    end

    return {
      type = "python_file",
      name = "Python File",
      path = file_dir,
      run_cmd = "python3 " .. vim.fn.shellescape(file),
      icon = "",
    }
  end

  -- Kotlin detection
  if filetype == "kotlin" then
    local gradle_root = find_root(file_dir, "build.gradle.kts")
      or find_root(file_dir, "build.gradle")

    if gradle_root then
      return {
        type = "gradle",
        name = "Gradle Project",
        path = gradle_root,
        build_cmd = "./gradlew build",
        run_cmd = "./gradlew run",
        test_cmd = "./gradlew test",
        icon = "",
      }
    end

    -- Single file - use kotlin scripting
    return {
      type = "kotlin_file",
      name = "Kotlin Script",
      path = file_dir,
      run_cmd = "kotlinc -script " .. vim.fn.shellescape(file),
      icon = "",
    }
  end

  -- C++ detection
  if filetype == "cpp" or filetype == "c" then
    local cmake_root = find_root(file_dir, "CMakeLists.txt")
    if cmake_root then
      return {
        type = "cmake",
        name = "CMake Project",
        path = cmake_root,
        build_cmd = "cmake -B build && cmake --build build",
        run_cmd = "cmake -B build && cmake --build build && ./build/$(basename " .. cmake_root .. ")",
        icon = "",
        error_pattern = "([^:]+):(%d+):(%d+): (%w+): (.+)",
      }
    end

    local make_root = find_root(file_dir, "Makefile")
    if make_root then
      return {
        type = "makefile",
        name = "Makefile Project",
        path = make_root,
        build_cmd = "make",
        run_cmd = "make run",
        icon = "",
      }
    end

    local out = "/tmp/codemate_" .. vim.fn.fnamemodify(file, ":t:r")
    local compiler = filetype == "cpp" and "g++ -std=c++17" or "gcc"
    return {
      type = "cpp_file",
      name = filetype == "cpp" and "C++ File" or "C File",
      path = file_dir,
      build_cmd = compiler .. " " .. vim.fn.shellescape(file) .. " -o " .. out,
      run_cmd = compiler .. " " .. vim.fn.shellescape(file) .. " -o " .. out .. " && " .. out,
      icon = "",
    }
  end

  -- Lua detection
  if filetype == "lua" then
    return {
      type = "lua_file",
      name = "Lua File",
      path = file_dir,
      run_cmd = "lua " .. vim.fn.shellescape(file),
      icon = "",
    }
  end

  return nil
end

-- Parse errors from output and populate quickfix
local function parse_errors(output, pattern, cwd)
  if not pattern then return end

  local qf_items = {}
  local full_output = table.concat(output, "\n")

  -- Common patterns for different languages
  local patterns = {
    -- Swift/Clang: file:line:col: error: message
    swift = "([^:\n]+):(%d+):(%d+): (%w+): ([^\n]+)",
    -- Rust: error[E0000]: message\n --> file:line:col
    rust = "error%[E%d+%]: ([^\n]+)\n%s+%-%-> ([^:]+):(%d+):(%d+)",
    -- Go/GCC: file:line:col: message
    gcc = "([^:\n]+):(%d+):(%d+): ([^\n]+)",
    -- Python: File "file", line N
    python = 'File "([^"]+)", line (%d+)',
  }

  -- Try swift/clang pattern
  for file, line, col, severity, msg in full_output:gmatch(patterns.swift) do
    if severity == "error" or severity == "warning" then
      table.insert(qf_items, {
        filename = file:sub(1, 1) == "/" and file or (cwd .. "/" .. file),
        lnum = tonumber(line),
        col = tonumber(col),
        text = msg,
        type = severity == "error" and "E" or "W",
      })
    end
  end

  -- Try GCC pattern if no results
  if #qf_items == 0 then
    for file, line, col, msg in full_output:gmatch(patterns.gcc) do
      if not file:match("^%d+$") then -- Avoid false matches
        table.insert(qf_items, {
          filename = file:sub(1, 1) == "/" and file or (cwd .. "/" .. file),
          lnum = tonumber(line),
          col = tonumber(col),
          text = msg,
          type = "E",
        })
      end
    end
  end

  -- Try Python pattern
  if #qf_items == 0 then
    for file, line in full_output:gmatch(patterns.python) do
      table.insert(qf_items, {
        filename = file:sub(1, 1) == "/" and file or (cwd .. "/" .. file),
        lnum = tonumber(line),
        col = 1,
        text = "Error",
        type = "E",
      })
    end
  end

  if #qf_items > 0 then
    vim.fn.setqflist(qf_items, "r")
    vim.fn.setqflist({}, "a", { title = "Codemate Errors" })
  end

  return #qf_items
end

-- Run command in a bottom terminal with history logging
function M.run_cmd(cmd, cwd, title, meta)
  meta = meta or {}

  -- Kill existing job if running
  if M.state.job_id and vim.fn.jobwait({ M.state.job_id }, 0)[1] == -1 then
    vim.fn.jobstop(M.state.job_id)
  end

  -- Store for re-run
  M.state.last_cmd = cmd
  M.state.last_cwd = cwd
  M.state.last_title = title
  M.state.last_meta = meta
  M.state.status = "running"
  M.state.progress = 0
  M.state.start_time = vim.loop.hrtime()

  -- Clear timeline and start tracking
  timeline.clear()
  local build_phase = timeline.start_phase("Build", "")

  -- Show start notification
  local notify_id = notify.start(meta.type or "run", meta.project_name or "Project")

  -- Create history record
  local record = history.add({
    type = meta.type or "run",
    project_type = meta.project_type,
    project_name = meta.project_name,
    project_path = cwd,
    cmd = cmd,
    icon = meta.icon or "",
  })

  local start_time = M.state.start_time
  local output_buffer = {}

  -- Reuse existing buffer/window or create new ones
  local buf = M.state.buf
  local win = M.state.win

  -- termopen requires an unmodified buffer, so always create fresh
  if buf and vim.api.nvim_buf_is_valid(buf) then
    -- Delete old buffer
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end

  buf = vim.api.nvim_create_buf(false, true)
  M.state.buf = buf

  pcall(vim.api.nvim_buf_set_name, buf, "codemate://" .. title)

  if not win or not vim.api.nvim_win_is_valid(win) then
    local height = math.floor(vim.o.lines * 0.3)
    vim.cmd("botright " .. height .. "split")
    win = vim.api.nvim_get_current_win()
    M.state.win = win
  else
    -- Focus existing window
    vim.api.nvim_set_current_win(win)
  end

  vim.api.nvim_win_set_buf(win, buf)

  -- Window options
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].winfixheight = true

  -- Clear quickfix
  vim.fn.setqflist({}, "r")

  -- Run the command in terminal
  M.state.job_id = vim.fn.termopen(cmd, {
    cwd = cwd,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          table.insert(output_buffer, line)
        end
        -- Update progress estimation based on output
        M.state.progress = math.min(95, M.state.progress + 1)
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          table.insert(output_buffer, line)
        end
      end
    end,
    on_exit = function(_, code)
      local duration = (vim.loop.hrtime() - start_time) / 1e9

      M.state.status = code == 0 and "success" or "failed"
      M.state.progress = 100
      M.state.job_id = nil

      -- End timeline phase
      timeline.end_phase(build_phase, code == 0)

      -- Update history record
      history.update(record.id, {
        exit_code = code,
        duration = duration,
      })

      -- Save output to log file
      history.append_log(record, table.concat(output_buffer, "\n"))

      -- Parse errors
      local error_count = parse_errors(output_buffer, meta.error_pattern, cwd)

      vim.schedule(function()
        -- Use nvim-notify for notifications
        if code == 0 then
          notify.success(meta.type or "run", meta.project_name or "Project", duration, notify_id)
        else
          notify.failure(meta.type or "run", meta.project_name or "Project", code, error_count, notify_id)
        end

        -- Update buffer name
        if vim.api.nvim_buf_is_valid(buf) then
          local status_str = code == 0 and "success" or "exit " .. code
          local new_name = string.format("codemate://%s [%s]", title, status_str)
          pcall(vim.api.nvim_buf_set_name, buf, new_name)
        end

        -- Exit terminal mode
        if vim.api.nvim_win_is_valid(win) then
          vim.cmd("stopinsert")
        end

        -- Auto-close on success if configured
        if code == 0 and meta.auto_close then
          vim.defer_fn(function()
            if vim.api.nvim_win_is_valid(win) then
              vim.api.nvim_win_close(win, true)
            end
          end, 1000)
        end

        -- For tests, show results in panel instead of quickfix
        if meta.type == "test" then
          local test_results = testpanel.parse(output_buffer, meta.project_type)
          if #test_results > 0 then
            testpanel.show(test_results)
          end
        elseif error_count and error_count > 0 then
          -- Open quickfix for build errors (not tests)
          vim.cmd("copen")
        end
      end)
    end,
  })

  -- Terminal mode keymaps
  local opts = { buffer = buf, nowait = true }

  vim.keymap.set("n", "q", function()
    M.close()
  end, opts)

  vim.keymap.set("n", "<Esc>", function()
    M.close()
  end, opts)

  vim.keymap.set("n", "<C-c>", function()
    M.stop()
  end, opts)

  -- Start in terminal mode
  vim.cmd("startinsert")
end

-- Stop running process
function M.stop()
  if M.state.job_id then
    vim.fn.jobstop(M.state.job_id)
    M.state.job_id = nil
    M.state.status = "idle"
    notify.stopped()
  else
    notify.info("No running process")
  end
end

-- Close terminal window
function M.close()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_win_close(M.state.win, true)
    M.state.win = nil
  end
end

-- Toggle terminal window
function M.toggle()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    M.close()
  elseif M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf) then
    local height = math.floor(vim.o.lines * 0.3)
    vim.cmd("botright " .. height .. "split")
    M.state.win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(M.state.win, M.state.buf)
    vim.wo[M.state.win].number = false
    vim.wo[M.state.win].relativenumber = false
    vim.wo[M.state.win].signcolumn = "no"
  else
    vim.notify("No terminal to toggle", vim.log.levels.INFO)
  end
end

-- Re-run last command
function M.rerun()
  if M.state.last_cmd then
    M.run_cmd(M.state.last_cmd, M.state.last_cwd, M.state.last_title, M.state.last_meta)
  else
    vim.notify("No previous command to re-run", vim.log.levels.WARN)
  end
end

-- Get status for statusline
function M.get_status()
  return {
    status = M.state.status,
    progress = M.state.progress,
    is_running = M.state.job_id ~= nil,
  }
end

function M.run()
  local project = detect_project()

  if not project then
    vim.notify("No runnable project detected", vim.log.levels.WARN)
    return
  end

  if not project.run_cmd then
    vim.notify("No run command for " .. project.name, vim.log.levels.WARN)
    return
  end

  if vim.bo.modified then
    vim.cmd("write")
  end

  local title = project.icon .. "  Run: " .. project.name
  M.run_cmd(project.run_cmd, project.path, title, {
    type = "run",
    project_type = project.type,
    project_name = project.name,
    icon = project.icon,
    error_pattern = project.error_pattern,
  })
end

function M.build()
  local project = detect_project()

  if not project then
    vim.notify("No buildable project detected", vim.log.levels.WARN)
    return
  end

  if not project.build_cmd then
    vim.notify("No build command for " .. project.name, vim.log.levels.WARN)
    return
  end

  if vim.bo.modified then
    vim.cmd("write")
  end

  local title = project.icon .. "  Build: " .. project.name
  M.run_cmd(project.build_cmd, project.path, title, {
    type = "build",
    project_type = project.type,
    project_name = project.name,
    icon = project.icon,
    error_pattern = project.error_pattern,
  })
end

function M.test()
  local project = detect_project()

  if not project then
    vim.notify("No testable project detected", vim.log.levels.WARN)
    return
  end

  if not project.test_cmd then
    vim.notify("No test command for " .. project.name, vim.log.levels.WARN)
    return
  end

  if vim.bo.modified then
    vim.cmd("write")
  end

  local title = project.icon .. "  Test: " .. project.name
  M.run_cmd(project.test_cmd, project.path, title, {
    type = "test",
    project_type = project.type,
    project_name = project.name,
    icon = project.icon,
    error_pattern = project.error_pattern,
  })
end

function M.info()
  local project = detect_project()

  if not project then
    vim.notify("No project detected", vim.log.levels.INFO)
    return
  end

  local lines = {
    project.icon .. "  " .. project.name,
    "",
    "Type: " .. project.type,
    "Path: " .. project.path,
  }

  if project.build_cmd then
    table.insert(lines, "Build: " .. project.build_cmd)
  end
  if project.run_cmd then
    table.insert(lines, "Run: " .. project.run_cmd)
  end
  if project.test_cmd then
    table.insert(lines, "Test: " .. project.test_cmd)
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

return M
