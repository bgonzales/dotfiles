local M = {}

local templates = require("codemate.templates")
local ui = require("codemate.ui")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local entry_display = require("telescope.pickers.entry_display")

-- Map language to file extension for devicons
local lang_to_ext = {
  swift = "swift",
  cpp = "cpp",
  c = "c",
  lua = "lua",
  rust = "rs",
  go = "go",
  python = "py",
  kotlin = "kt",
}

local function get_devicon(lang)
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if not ok then
    return "", nil
  end

  local ext = lang_to_ext[lang] or lang
  local icon, hl = devicons.get_icon(nil, ext, { default = true })
  return icon or "", hl
end

local function get_file_icon(filename)
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if not ok then
    return "", nil
  end

  local ext = filename:match("%.([^%.]+)$")
  local icon, hl = devicons.get_icon(filename, ext, { default = true })
  return icon or "", hl
end

-- Define project structures for preview
local project_structures = {
  -- Swift SPM
  spm = {
    { type = "folder", name = "{name}", children = {
      { type = "file", name = "Package.swift" },
      { type = "folder", name = "Sources", children = {
        { type = "folder", name = "{name}", children = {
          { type = "file", name = "{name}.swift" },
        }},
      }},
    }},
  },
  -- Xcode
  xcode = {
    { type = "folder", name = "{name}", children = {
      { type = "file", name = "project.yml" },
      { type = "folder", name = "Sources", children = {
        { type = "file", name = "main.swift" },
      }},
      { type = "file", name = "{name}.xcodeproj", generated = true },
    }},
  },
  -- C++ Makefile
  cpp_makefile = {
    { type = "folder", name = "{name}", children = {
      { type = "file", name = "Makefile" },
      { type = "folder", name = "src", children = {
        { type = "file", name = "main.cpp" },
      }},
      { type = "folder", name = "include", children = {} },
      { type = "folder", name = "build", generated = true, children = {} },
    }},
  },
  -- C++ CMake
  cpp_cmake = {
    { type = "folder", name = "{name}", children = {
      { type = "file", name = "CMakeLists.txt" },
      { type = "folder", name = "src", children = {
        { type = "file", name = "main.cpp" },
      }},
      { type = "folder", name = "include", children = {} },
      { type = "folder", name = "build", generated = true, children = {} },
    }},
  },
  -- Lua
  lua_project = {
    { type = "folder", name = "{name}", children = {
      { type = "folder", name = "src", children = {
        { type = "file", name = "main.lua" },
      }},
    }},
  },
  -- Rust Cargo
  cargo = {
    { type = "folder", name = "{name}", children = {
      { type = "file", name = "Cargo.toml" },
      { type = "folder", name = "src", children = {
        { type = "file", name = "main.rs" },
      }},
      { type = "folder", name = "target", generated = true, children = {} },
    }},
  },
  -- Go Module
  go_mod = {
    { type = "folder", name = "{name}", children = {
      { type = "file", name = "go.mod" },
      { type = "file", name = "main.go" },
    }},
  },
  -- Python venv
  python_venv = {
    { type = "folder", name = "{name}", children = {
      { type = "file", name = "main.py" },
      { type = "file", name = "requirements.txt" },
      { type = "folder", name = "venv", generated = true, children = {} },
    }},
  },
  -- Kotlin Gradle
  kotlin_gradle = {
    { type = "folder", name = "{name}", children = {
      { type = "file", name = "build.gradle.kts" },
      { type = "file", name = "settings.gradle.kts" },
      { type = "folder", name = "src", children = {
        { type = "folder", name = "main", children = {
          { type = "folder", name = "kotlin", children = {
            { type = "file", name = "Main.kt" },
          }},
        }},
      }},
    }},
  },
}

local function render_tree(structure, indent, project_name)
  local lines = {}
  local highlights = {} -- { line, col_start, col_end, hl_group }

  local folder_icon = ""
  local folder_open_icon = ""

  local function render_node(node, level, is_last, prefix)
    local indent_str = prefix
    local branch = is_last and "└── " or "├── "

    local name = node.name:gsub("{name}", project_name)
    local icon, hl

    if node.type == "folder" then
      icon = (node.children and #node.children > 0) and folder_open_icon or folder_icon
      hl = "Directory"
    else
      icon, hl = get_file_icon(name)
    end

    local line = indent_str .. branch .. icon .. " " .. name
    if node.generated then
      line = line .. "  (generated)"
    end

    local line_idx = #lines
    table.insert(lines, line)

    -- Store highlight info
    local icon_start = #indent_str + #branch
    local icon_end = icon_start + #icon
    if hl then
      table.insert(highlights, { line_idx, icon_start, icon_end, hl })
    end
    if node.generated then
      local gen_start = #line - 11
      table.insert(highlights, { line_idx, gen_start, #line, "Comment" })
    end

    -- Render children
    if node.children then
      local child_prefix = prefix .. (is_last and "    " or "│   ")
      for i, child in ipairs(node.children) do
        local child_is_last = (i == #node.children)
        render_node(child, level + 1, child_is_last, child_prefix)
      end
    end
  end

  for i, node in ipairs(structure) do
    render_node(node, 0, i == #structure, "")
  end

  return lines, highlights
end

local function get_structure_key(template)
  if template.lang == "swift" and template.name:match("SPM") then
    return "spm"
  elseif template.lang == "swift" and template.name:match("Xcode") then
    return "xcode"
  elseif template.lang == "cpp" and template.name:match("Makefile") then
    return "cpp_makefile"
  elseif template.lang == "cpp" and template.name:match("CMake") then
    return "cpp_cmake"
  elseif template.lang == "lua" and template.type == "project" then
    return "lua_project"
  elseif template.lang == "rust" and template.name:match("Cargo") then
    return "cargo"
  elseif template.lang == "go" and template.name:match("Module") then
    return "go_mod"
  elseif template.lang == "python" and template.name:match("venv") then
    return "python_venv"
  elseif template.lang == "kotlin" and template.name:match("Gradle") then
    return "kotlin_gradle"
  end
  return nil
end

local config = {
  base_dir = vim.fn.expand("~/Developer"),
}

function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})
end

local function create_previewer()
  return previewers.new_buffer_previewer({
    title = "Template Preview",
    define_preview = function(self, entry)
      local template = entry.value
      local buf = self.state.bufnr
      local ns = vim.api.nvim_create_namespace("codemate_preview")

      -- Skip separators
      if template.is_separator then
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
        return
      end

      local lines = {}
      local highlights = {}

      -- Header
      local icon, icon_hl = get_devicon(template.lang)
      table.insert(lines, icon .. "  " .. template.name)
      table.insert(highlights, { 0, icon_hl or "Normal", 0, #icon })
      table.insert(highlights, { 0, "Title", #icon + 2, -1 })
      table.insert(lines, "")

      -- Requirements section
      if template.requires and #template.requires > 0 then
        table.insert(lines, "Requirements:")
        table.insert(highlights, { #lines - 1, "Special", 0, -1 })

        for _, req in ipairs(template.requires) do
          local checker = templates.requirements[req]
          local installed = checker and checker()
          local status_icon = installed and "" or ""
          local status_hl = installed and "DiagnosticOk" or "DiagnosticError"
          local line = "  " .. status_icon .. " " .. req
          table.insert(lines, line)
          table.insert(highlights, { #lines - 1, status_hl, 2, 5 })
        end

        -- Install hint if missing
        if template.missing and #template.missing > 0 and template.install_hint then
          table.insert(lines, "")
          table.insert(lines, "Install: " .. template.install_hint)
          table.insert(highlights, { #lines - 1, "Comment", 0, -1 })
        end

        table.insert(lines, "")
      end

      if template.type == "file" then
        -- Show file content
        table.insert(lines, "Content Preview:")
        table.insert(highlights, { #lines - 1, "Comment", 0, -1 })
        table.insert(lines, "")

        local content_lines = vim.split(template.content or "", "\n")
        for _, line in ipairs(content_lines) do
          table.insert(lines, line)
        end

        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        -- Set filetype for syntax highlighting on content part
        vim.bo[buf].filetype = template.lang
      else
        -- Show project structure as tree
        table.insert(lines, "Project Structure:")
        table.insert(highlights, { #lines - 1, "Comment", 0, -1 })
        table.insert(lines, "")

        local structure_key = get_structure_key(template)
        if structure_key and project_structures[structure_key] then
          local tree_lines, tree_highlights = render_tree(
            project_structures[structure_key],
            "",
            "MyProject"
          )

          -- Offset highlights by header lines
          local offset = #lines
          for _, hl in ipairs(tree_highlights) do
            table.insert(highlights, { hl[1] + offset, hl[2], hl[3], hl[4] })
          end

          vim.list_extend(lines, tree_lines)
        end

        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      end

      -- Apply highlights
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      for _, hl in ipairs(highlights) do
        pcall(vim.api.nvim_buf_add_highlight, buf, ns, hl[2], hl[1], hl[3], hl[4])
      end
    end,
  })
end

local function create_file(template, name)
  local cwd = vim.fn.getcwd()
  local filename = cwd .. "/" .. name .. "." .. template.extension

  local file = io.open(filename, "w")
  if file then
    file:write(template.content)
    file:close()
    vim.cmd("edit " .. vim.fn.fnameescape(filename))
    vim.notify("Created: " .. name .. "." .. template.extension, vim.log.levels.INFO)
  else
    vim.notify("Failed to create file: " .. filename, vim.log.levels.ERROR)
  end
end

local function create_project(template, name)
  local cwd = vim.fn.getcwd()
  local path = cwd .. "/" .. name

  if vim.fn.isdirectory(path) == 1 then
    vim.notify("Directory already exists: " .. path, vim.log.levels.ERROR)
    return
  end

  local spec = template.create(path, name)

  -- Run pre-creation (sync, fast file operations)
  if spec.pre then
    spec.pre()
  end

  -- If there's an async command, run it with loading indicator
  if spec.cmd then
    local status = ui.float_status({ message = "Creating " .. template.name .. "..." })

    vim.fn.jobstart(spec.cmd, {
      on_exit = function(_, code)
        vim.schedule(function()
          status.close()

          if code == 0 then
            -- Run post-creation hook if defined
            if spec.post then
              spec.post()
            end

            vim.cmd("edit " .. vim.fn.fnameescape(spec.entry_file))
            vim.notify("Created: " .. name, vim.log.levels.INFO)
          else
            vim.notify("Failed to create project", vim.log.levels.ERROR)
          end

          if spec.post_warning then
            vim.notify(spec.post_warning, vim.log.levels.WARN)
          end
        end)
      end,
    })
  else
    -- Run post-creation hook if defined
    if spec.post then
      spec.post()
    end

    -- No async command, just open the file
    vim.cmd("edit " .. vim.fn.fnameescape(spec.entry_file))
    vim.notify("Created: " .. name, vim.log.levels.INFO)

    if spec.post_warning then
      vim.notify(spec.post_warning, vim.log.levels.WARN)
    end
  end
end

local function prompt_name_and_create(template)
  local prompt = template.type == "file" and "File name" or "Project name"

  -- Use enhanced input with preview for projects
  if template.type == "project" then
    ui.float_input_with_preview({
      prompt = prompt,
      width = 40,
      template = template,
    }, function(name)
      create_project(template, name)
    end)
  else
    ui.float_input({ prompt = prompt, width = 40 }, function(name)
      create_file(template, name)
    end)
  end
end

function M.pick_template()
  local available, unavailable = templates.get_grouped()

  -- Combine with separator
  local all_templates = {}
  for _, t in ipairs(available) do
    t.is_available = true
    table.insert(all_templates, t)
  end
  if #unavailable > 0 then
    -- Add blank line and separator
    table.insert(all_templates, { is_separator = true, name = "" })
    table.insert(all_templates, { is_separator = true, name = "── Unavailable (missing dependencies) ──" })
    for _, t in ipairs(unavailable) do
      t.is_available = false
      table.insert(all_templates, t)
    end
  end

  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 2 },  -- icon
      { width = 1 },  -- type icon (file/project)
      { width = 1 },  -- status icon
      { remaining = true }, -- name
    },
  })

  local function make_display(entry)
    local template = entry.value

    -- Separator line
    if template.is_separator then
      return displayer({
        { "", "Comment" },
        { "", "Comment" },
        { "", "Comment" },
        { template.name, "Comment" },
      })
    end

    local icon, icon_hl = get_devicon(template.lang)
    local type_icon = template.type == "file" and "" or ""
    local status_icon = template.is_available and "" or ""
    local status_hl = template.is_available and "DiagnosticOk" or "DiagnosticError"

    if template.is_available then
      return displayer({
        { icon, icon_hl },
        { type_icon },
        { status_icon, status_hl },
        { template.name },
      })
    else
      return displayer({
        { icon, "Comment" },
        { type_icon, "Comment" },
        { status_icon, status_hl },
        { template.name, "Comment" },
      })
    end
  end

  pickers.new({}, {
    prompt_title = "  New Project/File",
    finder = finders.new_table({
      results = all_templates,
      entry_maker = function(entry)
        return {
          value = entry,
          display = make_display,
          ordinal = entry.lang and (entry.lang .. " " .. entry.name) or entry.name,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = create_previewer(),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        if not selection or selection.value.is_separator then
          return
        end

        local template = selection.value
        if not template.is_available then
          vim.notify(
            "Missing: " .. table.concat(template.missing, ", ") .. "\n" .. (template.install_hint or ""),
            vim.log.levels.WARN
          )
          return
        end

        actions.close(prompt_bufnr)
        -- Small delay to let telescope close properly
        vim.schedule(function()
          prompt_name_and_create(template)
        end)
      end)
      return true
    end,
  }):find()
end

return M
