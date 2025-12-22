return {
  dir = vim.fn.stdpath("config") .. "/lua/codemate",
  name = "codemate",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "rcarriga/nvim-notify",
  },
  config = function()
    require("codemate").setup({
      keymaps = {
        new_project = "<leader>cp",     -- Create new project/file
        run = "<leader>cr",             -- Run project/file
        build = "<leader>cb",           -- Build project
        test = "<leader>ct",            -- Test project
        info = "<leader>ci",            -- Show project info
        history = "<leader>ca",         -- Show all history
        history_current = "<leader>ch", -- Show current project history
        stop = "<leader>ck",            -- Kill/stop process
        rerun = "<leader>cl",           -- Re-run last command
        toggle = "<leader>co",          -- Toggle output window
        menu = "<leader>cc",            -- Quick actions menu
        dashboard = "<leader>cd",       -- Project dashboard
        timeline = "<leader>cT",        -- Build timeline
      },
    })
  end,
}
