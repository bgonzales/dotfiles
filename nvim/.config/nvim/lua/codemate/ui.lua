local M = {}

function M.float_input(opts, on_confirm)
  opts = opts or {}
  local prompt = opts.prompt or "Input: "
  local default = opts.default or ""
  local width = opts.width or 40

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { default })

  -- Window dimensions
  local win_opts = {
    relative = "editor",
    width = width,
    height = 1,
    row = math.floor((vim.o.lines - 3) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. prompt .. " ",
    title_pos = "center",
  }

  local win = vim.api.nvim_open_win(buf, true, win_opts)

  -- Buffer options
  vim.bo[buf].buftype = "prompt"
  vim.fn.prompt_setprompt(buf, "")

  -- Window options
  vim.wo[win].wrap = false

  -- Start insert mode at end
  vim.cmd("startinsert!")
  vim.api.nvim_win_set_cursor(win, { 1, #default })

  local function close_window()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  local function confirm()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, 1, false)
    local value = lines[1] or ""
    close_window()
    vim.schedule(function()
      if value ~= "" then
        on_confirm(value)
      else
        vim.notify("Cancelled", vim.log.levels.INFO)
      end
    end)
  end

  -- Keymaps
  vim.keymap.set({ "i", "n" }, "<CR>", confirm, { buffer = buf, nowait = true })
  vim.keymap.set({ "i", "n" }, "<Esc>", close_window, { buffer = buf, nowait = true })
  vim.keymap.set({ "i", "n" }, "<C-c>", close_window, { buffer = buf, nowait = true })
end

function M.float_status(opts)
  opts = opts or {}
  local title = opts.title or "codemate"
  local message = opts.message or "Loading..."
  local width = math.max(#message + 8, 40)

  local buf = vim.api.nvim_create_buf(false, true)

  local spinner_frames = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" }
  local spinner_idx = 1

  -- Create highlight namespace
  local ns = vim.api.nvim_create_namespace("codemate_status")

  local win_opts = {
    relative = "editor",
    width = width,
    height = 3,
    row = math.floor((vim.o.lines - 5) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
  }

  local win = vim.api.nvim_open_win(buf, false, win_opts)

  -- Set window options for better appearance
  vim.wo[win].winhl = "Normal:Normal,FloatBorder:FloatBorder"

  local function render()
    local spinner = spinner_frames[spinner_idx]
    local lines = {
      "",
      "    " .. spinner .. "  " .. message,
      "",
    }
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- Highlight spinner
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, ns, "Special", 1, 4, 7)
  end

  render()

  local timer = vim.loop.new_timer()
  timer:start(0, 100, vim.schedule_wrap(function()
    if not vim.api.nvim_buf_is_valid(buf) then
      timer:stop()
      timer:close()
      return
    end
    spinner_idx = (spinner_idx % #spinner_frames) + 1
    render()
  end))

  return {
    close = function()
      timer:stop()
      timer:close()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end,
    update = function(new_message)
      message = new_message
      if vim.api.nvim_buf_is_valid(buf) then
        render()
      end
    end,
  }
end

-- Enhanced input with live preview for templates
function M.float_input_with_preview(opts, on_confirm)
  opts = opts or {}
  local prompt = opts.prompt or "Name: "
  local default = opts.default or ""
  local width = opts.width or 50
  local preview_fn = opts.preview -- function(name) returns { lines, highlights }
  local template = opts.template

  local ns = vim.api.nvim_create_namespace("codemate_preview_input")

  -- Create input buffer
  local input_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, { default })

  -- Create preview buffer
  local preview_buf = vim.api.nvim_create_buf(false, true)

  -- Calculate positions - vertical layout (input on top, preview below)
  local preview_height = 12
  local total_height = 1 + 1 + preview_height -- input + gap + preview
  local start_row = math.floor((vim.o.lines - total_height) / 2)
  local start_col = math.floor((vim.o.columns - width) / 2)

  -- Input window (top)
  local input_win = vim.api.nvim_open_win(input_buf, true, {
    relative = "editor",
    width = width,
    height = 1,
    row = start_row,
    col = start_col,
    style = "minimal",
    border = "rounded",
    title = " " .. prompt .. " ",
    title_pos = "center",
  })

  -- Preview window (below input)
  local preview_win = vim.api.nvim_open_win(preview_buf, false, {
    relative = "editor",
    width = width,
    height = preview_height,
    row = start_row + 4, -- input height + border + gap
    col = start_col,
    style = "minimal",
    border = "rounded",
    title = " Preview ",
    title_pos = "center",
  })

  vim.wo[preview_win].wrap = false

  -- Buffer options for input
  vim.bo[input_buf].buftype = "prompt"
  vim.fn.prompt_setprompt(input_buf, "")
  vim.wo[input_win].wrap = false

  local function update_preview(name)
    if not name or name == "" then
      name = "MyProject"
    end

    local lines = {}
    local highlights = {}

    if template then
      -- Header
      local ok, devicons = pcall(require, "nvim-web-devicons")
      local icon = ""
      if ok then
        local lang_to_ext = { swift = "swift", cpp = "cpp", lua = "lua", rust = "rs", go = "go", python = "py", kotlin = "kt" }
        local ext = lang_to_ext[template.lang] or template.lang
        icon = devicons.get_icon(nil, ext, { default = true }) or ""
      end

      table.insert(lines, icon .. "  " .. template.name)
      table.insert(highlights, { 0, "Title", 0, -1 })
      table.insert(lines, "")

      if template.type == "file" then
        table.insert(lines, "File: " .. name .. "." .. (template.extension or ""))
        table.insert(highlights, { 2, "String", 6, -1 })
        table.insert(lines, "")
        table.insert(lines, "Content Preview:")
        table.insert(highlights, { 4, "Comment", 0, -1 })
        table.insert(lines, "")

        -- Show first few lines of content
        if template.content then
          local content_lines = vim.split(template.content, "\n")
          for i = 1, math.min(6, #content_lines) do
            table.insert(lines, "  " .. content_lines[i])
          end
          if #content_lines > 6 then
            table.insert(lines, "  ...")
            table.insert(highlights, { #lines - 1, "Comment", 0, -1 })
          end
        end
      else
        table.insert(lines, "Project: " .. name)
        table.insert(highlights, { 2, "String", 9, -1 })
        table.insert(lines, "")
        table.insert(lines, "Structure:")
        table.insert(highlights, { 4, "Comment", 0, -1 })
        table.insert(lines, "")

        -- Render tree structure
        local tree = render_simple_tree(template, name)
        for _, line in ipairs(tree) do
          table.insert(lines, line)
        end
      end
    end

    vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
    vim.api.nvim_buf_clear_namespace(preview_buf, ns, 0, -1)

    for _, hl in ipairs(highlights) do
      vim.api.nvim_buf_add_highlight(preview_buf, ns, hl[2], hl[1], hl[3], hl[4])
    end
  end

  -- Helper to render tree
  function render_simple_tree(tmpl, name)
    local lines = {}
    local folder_icon = ""
    local file_icon = ""
    local test_icon = ""

    if tmpl.lang == "swift" and tmpl.name:match("SPM") then
      table.insert(lines, folder_icon .. " " .. name)
      table.insert(lines, "  ├── " .. file_icon .. " Package.swift")
      table.insert(lines, "  ├── " .. folder_icon .. " Sources")
      table.insert(lines, "  │   └── " .. folder_icon .. " " .. name)
      table.insert(lines, "  │       └── " .. file_icon .. " " .. name .. ".swift")
      table.insert(lines, "  └── " .. folder_icon .. " Tests")
      table.insert(lines, "      └── " .. test_icon .. " " .. name .. "Tests.swift")
    elseif tmpl.lang == "rust" then
      table.insert(lines, folder_icon .. " " .. name)
      table.insert(lines, "  ├── " .. file_icon .. " Cargo.toml")
      table.insert(lines, "  └── " .. folder_icon .. " src")
      table.insert(lines, "      └── " .. file_icon .. " main.rs")
    elseif tmpl.lang == "go" then
      table.insert(lines, folder_icon .. " " .. name)
      table.insert(lines, "  ├── " .. file_icon .. " go.mod")
      table.insert(lines, "  ├── " .. file_icon .. " main.go")
      table.insert(lines, "  └── " .. test_icon .. " main_test.go")
    elseif tmpl.lang == "python" then
      table.insert(lines, folder_icon .. " " .. name)
      table.insert(lines, "  ├── " .. file_icon .. " main.py")
      table.insert(lines, "  ├── " .. file_icon .. " requirements.txt")
      table.insert(lines, "  ├── " .. folder_icon .. " tests")
      table.insert(lines, "  │   └── " .. test_icon .. " test_main.py")
      table.insert(lines, "  └── " .. folder_icon .. " venv/")
    elseif tmpl.lang == "kotlin" then
      table.insert(lines, folder_icon .. " " .. name)
      table.insert(lines, "  ├── " .. file_icon .. " build.gradle.kts")
      table.insert(lines, "  └── " .. folder_icon .. " src")
      table.insert(lines, "      ├── " .. folder_icon .. " main/kotlin")
      table.insert(lines, "      │   └── " .. file_icon .. " Main.kt")
      table.insert(lines, "      └── " .. folder_icon .. " test/kotlin")
      table.insert(lines, "          └── " .. test_icon .. " MainTest.kt")
    elseif tmpl.lang == "cpp" and tmpl.name:match("CMake") then
      table.insert(lines, folder_icon .. " " .. name)
      table.insert(lines, "  ├── " .. file_icon .. " CMakeLists.txt")
      table.insert(lines, "  ├── " .. folder_icon .. " src")
      table.insert(lines, "  │   └── " .. file_icon .. " main.cpp")
      table.insert(lines, "  └── " .. folder_icon .. " include")
    elseif tmpl.lang == "cpp" and tmpl.name:match("Makefile") then
      table.insert(lines, folder_icon .. " " .. name)
      table.insert(lines, "  ├── " .. file_icon .. " Makefile")
      table.insert(lines, "  ├── " .. folder_icon .. " src")
      table.insert(lines, "  │   └── " .. file_icon .. " main.cpp")
      table.insert(lines, "  └── " .. folder_icon .. " include")
    else
      table.insert(lines, folder_icon .. " " .. name)
      table.insert(lines, "  └── " .. file_icon .. " main." .. (tmpl.extension or tmpl.lang))
    end

    return lines
  end

  -- Initial preview
  update_preview(default)

  -- Start insert mode
  vim.cmd("startinsert!")
  vim.api.nvim_win_set_cursor(input_win, { 1, #default })

  -- Update preview on text change
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = input_buf,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(input_buf, 0, 1, false)
      local name = lines[1] or ""
      update_preview(name)
    end,
  })

  local function close_windows()
    if vim.api.nvim_win_is_valid(input_win) then
      vim.api.nvim_win_close(input_win, true)
    end
    if vim.api.nvim_win_is_valid(preview_win) then
      vim.api.nvim_win_close(preview_win, true)
    end
    if vim.api.nvim_buf_is_valid(input_buf) then
      vim.api.nvim_buf_delete(input_buf, { force = true })
    end
    if vim.api.nvim_buf_is_valid(preview_buf) then
      vim.api.nvim_buf_delete(preview_buf, { force = true })
    end
  end

  local function confirm()
    local lines = vim.api.nvim_buf_get_lines(input_buf, 0, 1, false)
    local value = lines[1] or ""
    close_windows()
    vim.schedule(function()
      if value ~= "" then
        on_confirm(value)
      else
        vim.notify("Cancelled", vim.log.levels.INFO)
      end
    end)
  end

  -- Keymaps
  vim.keymap.set({ "i", "n" }, "<CR>", confirm, { buffer = input_buf, nowait = true })
  vim.keymap.set({ "i", "n" }, "<Esc>", close_windows, { buffer = input_buf, nowait = true })
  vim.keymap.set({ "i", "n" }, "<C-c>", close_windows, { buffer = input_buf, nowait = true })
end

return M
