local M = {}

local ns = vim.api.nvim_create_namespace("codemate_testpanel")

M.state = {
  buf = nil,
  win = nil,
  results = {},
}

local icons = {
  passed = "",
  failed = "",
  skipped = "",
  suite = "",
}

-- Parse test results from output
function M.parse_swift_tests(output)
  local results = {}
  local full_output = table.concat(output, "\n")

  -- Swift Testing format: ✔ Test "testName" passed | ✘ Test "testName" failed
  for status, name in full_output:gmatch("([✔✘◇]) Test \"([^\"]+)\"") do
    table.insert(results, {
      name = name,
      passed = status == "✔",
      skipped = status == "◇",
    })
  end

  -- Also try XCTest format: Test Case '-[TestClass testMethod]' passed/failed
  for class, method, status in full_output:gmatch("Test Case '%-?%[([^%s]+) ([^%]]+)%]' (%w+)") do
    table.insert(results, {
      name = class .. "." .. method,
      passed = status == "passed",
      skipped = false,
    })
  end

  -- Swift Testing suite format
  for name, passed, failed in full_output:gmatch("◇ Test run .+ (%d+) tests?, (%d+) passed, (%d+) failed") do
    -- Summary line, skip
  end

  return results
end

function M.parse_cargo_tests(output)
  local results = {}
  local full_output = table.concat(output, "\n")

  -- Rust format: test name ... ok/FAILED
  for name, status in full_output:gmatch("test ([^%s]+) %.%.%. (%w+)") do
    table.insert(results, {
      name = name,
      passed = status == "ok",
      skipped = status == "ignored",
    })
  end

  return results
end

function M.parse_go_tests(output)
  local results = {}
  local full_output = table.concat(output, "\n")

  -- Go format: --- PASS: TestName (0.00s) or --- FAIL: TestName (0.00s)
  for status, name in full_output:gmatch("%-%-%-  ?(%w+): ([^%s]+)") do
    table.insert(results, {
      name = name,
      passed = status == "PASS",
      skipped = status == "SKIP",
    })
  end

  return results
end

function M.parse_pytest(output)
  local results = {}
  local full_output = table.concat(output, "\n")

  -- Pytest format: test_file.py::test_name PASSED/FAILED
  for name, status in full_output:gmatch("([^%s]+::[^%s]+) (%w+)") do
    table.insert(results, {
      name = name,
      passed = status == "PASSED",
      skipped = status == "SKIPPED",
    })
  end

  return results
end

function M.parse_gradle_tests(output)
  local results = {}
  local full_output = table.concat(output, "\n")

  -- Gradle/JUnit format varies, try common patterns
  for name in full_output:gmatch("✓ ([^\n]+)") do
    table.insert(results, { name = name, passed = true, skipped = false })
  end
  for name in full_output:gmatch("✗ ([^\n]+)") do
    table.insert(results, { name = name, passed = false, skipped = false })
  end

  return results
end

-- Auto-detect and parse based on project type
function M.parse(output, project_type)
  if project_type == "spm" or project_type == "swift_file" then
    return M.parse_swift_tests(output)
  elseif project_type == "cargo" then
    return M.parse_cargo_tests(output)
  elseif project_type == "go_mod" or project_type == "go_file" then
    return M.parse_go_tests(output)
  elseif project_type == "python_project" or project_type == "python_file" then
    return M.parse_pytest(output)
  elseif project_type == "gradle" then
    return M.parse_gradle_tests(output)
  end

  return {}
end

-- Render test results in the panel
local function render(buf)
  local lines = {}
  local highlights = {}

  local passed = 0
  local failed = 0
  local skipped = 0

  for _, result in ipairs(M.state.results) do
    if result.passed then
      passed = passed + 1
    elseif result.skipped then
      skipped = skipped + 1
    else
      failed = failed + 1
    end
  end

  -- Header
  table.insert(lines, " Test Results")
  table.insert(highlights, { #lines - 1, "Title", 0, -1 })
  table.insert(lines, "")

  -- Summary
  local summary = string.format(" %d passed", passed)
  if failed > 0 then
    summary = summary .. string.format("   %d failed", failed)
  end
  if skipped > 0 then
    summary = summary .. string.format("   %d skipped", skipped)
  end
  table.insert(lines, summary)
  table.insert(highlights, { #lines - 1, failed > 0 and "DiagnosticError" or "DiagnosticOk", 0, -1 })
  table.insert(lines, "")
  table.insert(lines, string.rep("─", 30))
  table.insert(highlights, { #lines - 1, "Comment", 0, -1 })
  table.insert(lines, "")

  -- Individual results
  for _, result in ipairs(M.state.results) do
    local icon, hl
    if result.passed then
      icon = icons.passed
      hl = "DiagnosticOk"
    elseif result.skipped then
      icon = icons.skipped
      hl = "DiagnosticWarn"
    else
      icon = icons.failed
      hl = "DiagnosticError"
    end

    local line = string.format(" %s %s", icon, result.name)
    table.insert(lines, line)
    table.insert(highlights, { #lines - 1, hl, 0, 4 })
  end

  if #M.state.results == 0 then
    table.insert(lines, " No test results parsed")
    table.insert(highlights, { #lines - 1, "Comment", 0, -1 })
  end

  table.insert(lines, "")
  table.insert(lines, " Press q to close")
  table.insert(highlights, { #lines - 1, "Comment", 0, -1 })

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Apply highlights
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(buf, ns, hl[2], hl[1], hl[3], hl[4])
  end
end

-- Show test results in a bottom panel
function M.show(results)
  M.state.results = results or {}

  -- Close existing panel
  M.close()

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "codemate_tests"
  vim.bo[buf].modifiable = true
  M.state.buf = buf

  -- Create bottom split
  local height = math.min(#results + 8, 15)
  vim.cmd("botright " .. height .. "split")

  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  M.state.win = win

  -- Window options
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].winfixheight = true
  vim.wo[win].wrap = true
  vim.wo[win].cursorline = false

  -- Render content
  render(buf)
  vim.bo[buf].modifiable = false

  -- Keymaps
  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "q", function() M.close() end, opts)
  vim.keymap.set("n", "<Esc>", function() M.close() end, opts)

  -- Return focus to previous window
  vim.cmd("wincmd p")
end

function M.close()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_win_close(M.state.win, true)
  end
  M.state.win = nil
  M.state.buf = nil
end

function M.toggle()
  if M.state.win and vim.api.nvim_win_is_valid(M.state.win) then
    M.close()
  elseif #M.state.results > 0 then
    M.show(M.state.results)
  end
end

return M
