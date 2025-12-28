local M = {}

local defaults = {
  keymaps = {
    new_project = "<leader>cp",
    run = "<leader>cr",
    build = "<leader>cb",
    test = "<leader>ct",
    info = "<leader>ci",
    history = "<leader>ca",         -- all history
    history_current = "<leader>ch", -- current project history
    stop = "<leader>ck",            -- kill/stop
    rerun = "<leader>cl",           -- re-run last
    toggle = "<leader>cy",          -- toggle output
    menu = "<leader>cc",            -- quick actions menu
    dashboard = "<leader>cd",       -- project dashboard
    timeline = "<leader>cT",        -- build timeline
  },
}

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", defaults, opts or {})

  local runner = require("codemate.runner")
  local history = require("codemate.history")

  -- Keymaps
  vim.keymap.set("n", opts.keymaps.new_project, function()
    require("codemate.picker").pick_template()
  end, { desc = "[C]odemate new [P]roject" })

  vim.keymap.set("n", opts.keymaps.run, function()
    runner.run()
  end, { desc = "[C]odemate [R]un" })

  vim.keymap.set("n", opts.keymaps.build, function()
    runner.build()
  end, { desc = "[C]odemate [B]uild" })

  vim.keymap.set("n", opts.keymaps.test, function()
    runner.test()
  end, { desc = "[C]odemate [T]est" })

  vim.keymap.set("n", opts.keymaps.info, function()
    runner.info()
  end, { desc = "[C]odemate [I]nfo" })

  vim.keymap.set("n", opts.keymaps.stop, function()
    runner.stop()
  end, { desc = "[C]odemate [K]ill/stop" })

  vim.keymap.set("n", opts.keymaps.rerun, function()
    runner.rerun()
  end, { desc = "[C]odemate re-run [L]ast" })

  vim.keymap.set("n", opts.keymaps.toggle, function()
    runner.toggle()
  end, { desc = "[C]odemate toggle output [Y]" })

  vim.keymap.set("n", opts.keymaps.history, function()
    history.pick()
  end, { desc = "[C]odemate history [A]ll" })

  vim.keymap.set("n", opts.keymaps.history_current, function()
    history.pick_current()
  end, { desc = "[C]odemate [h]istory (current project)" })

  vim.keymap.set("n", opts.keymaps.menu, function()
    require("codemate.menu").open()
  end, { desc = "[C]odemate [C]ommand menu" })

  vim.keymap.set("n", opts.keymaps.dashboard, function()
    require("codemate.dashboard").open()
  end, { desc = "[C]odemate [D]ashboard" })

  vim.keymap.set("n", opts.keymaps.timeline, function()
    require("codemate.timeline").show()
  end, { desc = "[C]odemate [T]imeline" })

  -- Commands
  vim.api.nvim_create_user_command("CodemateNew", function()
    require("codemate.picker").pick_template()
  end, { desc = "Create new project or file" })

  vim.api.nvim_create_user_command("CodemateRun", function()
    runner.run()
  end, { desc = "Run current project/file" })

  vim.api.nvim_create_user_command("CodemateBuild", function()
    runner.build()
  end, { desc = "Build current project" })

  vim.api.nvim_create_user_command("CodemateTest", function()
    runner.test()
  end, { desc = "Test current project" })

  vim.api.nvim_create_user_command("CodemateInfo", function()
    runner.info()
  end, { desc = "Show project info" })

  vim.api.nvim_create_user_command("CodemateStop", function()
    runner.stop()
  end, { desc = "Stop running process" })

  vim.api.nvim_create_user_command("CodemateRerun", function()
    runner.rerun()
  end, { desc = "Re-run last command" })

  vim.api.nvim_create_user_command("CodemateToggle", function()
    runner.toggle()
  end, { desc = "Toggle output window" })

  vim.api.nvim_create_user_command("CodemateHistory", function()
    history.pick()
  end, { desc = "Show build/run history (all)" })

  vim.api.nvim_create_user_command("CodemateHistoryCurrent", function()
    history.pick_current()
  end, { desc = "Show build/run history (current project)" })

  vim.api.nvim_create_user_command("CodemateClearHistory", function()
    history.clear()
  end, { desc = "Clear all history" })

  vim.api.nvim_create_user_command("CodemateMenu", function()
    require("codemate.menu").open()
  end, { desc = "Open quick actions menu" })

  vim.api.nvim_create_user_command("CodemateDashboard", function()
    require("codemate.dashboard").open()
  end, { desc = "Open project dashboard" })

  vim.api.nvim_create_user_command("CodemateTimeline", function()
    require("codemate.timeline").show()
  end, { desc = "Show build timeline" })
end

return M
