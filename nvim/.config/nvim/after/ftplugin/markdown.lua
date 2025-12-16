-- Use macOS Dictionary.app for word lookup with K
vim.keymap.set("n", "K", function()
  local word = vim.fn.expand("<cword>")
  vim.fn.system("open dict://" .. word)
end, { buffer = true, desc = "Look up word in Dictionary.app" })
